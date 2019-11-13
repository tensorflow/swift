/// Data about an expression that is used during random expression generation.
fileprivate struct ExprInfo {
    /// The expression itself.
    var expr: Expr

    /// The type of the expression.
    var type: Type

    /// Whether the expression is varied (in the AutoDiff sense).
    var varied: Bool

    /// A score for the expression that tries to noisly capture how "interesting" it is.
    ///
    /// Random expression generation tries to make expressions with high scores. The score of a
    /// composite expression is the sum of scores of its component expressions (plus some noise).
    /// Leaf expressions are scored based on how interesting they seem. Some examples in order of most
    /// to least interesting:
    ///   1. References to varied arguments.
    ///   2. References to nonvaried arguments.
    ///   3. Literals.
    var score: Int
}

extension Expr {
    /// Create the simplest possible expression with the given type.
    init(simplestWithType type: Type) {
        switch type {
        case .float:
            self = .floatLiteral("0")
        case .int:
            self = .intLiteral("0")
        case .structType(let node):
            self = .apply(f: .declRef(node.noArgumentInit), args: [])
        default:
            fatalError("generateSimplest not implemented for \(type)")
        }
    }

    /// Create a random expression with the given type.
    init(randomWithType type: Type, in node: Node, conf: GeneratorConfiguration) {
        var candidates: [ExprInfo] = Expr.simpleExpressions(in: node)
        candidates += candidates.flatMap { Expr.memberExpressions($0, in: node) }
        for _ in 0..<2 {
            candidates.sort(by: { $0.score > $1.score })
            candidates += candidates.compactMap {
                Expr.applyExpression(f: $0, candidateArgs: candidates)
            }
        }
        candidates.sort(by: { $0.score > $1.score })

        if let result = candidates.first(where: { $0.type == type }) {
            self = result.expr
            return
        }

        self.init(simplestWithType: type)
    }

    /// Returns a list of simple expressions (e.g. literals, declRefs to visible decls) that can be
    /// written in the given node.
    private static func simpleExpressions(in node: Node) -> [ExprInfo] {
        var results: [ExprInfo] = []

        for n in node.referencableDecls() {
            // Forbid recursion.
            if let parentFunction = node.ancestor(FunctionNode.self), n == parentFunction {
                continue
            }

            var score = (-100...100).randomElement()!

            let varied: Bool
            if let argumentNode = n as? ArgumentNode {
                let signature = argumentNode.parent as! SignatureNode
                varied = signature.differentiableAttribute
                    && argumentNode.type.conforms(to: .differentiable)
                score += 100
                if varied { score += 100 }
            } else {
                varied = false
            }

            results.append(
                ExprInfo(
                    expr: .declRef(n),
                    type: n.declRefType,
                    varied: varied,
                    score: score))
        }

        results.append(
            ExprInfo(
                expr: .intLiteral("0"),
                type: .int,
                varied: false,
                score: 0))
        results.append(
            ExprInfo(
                expr: .floatLiteral("0"),
                type: .float,
                varied: false,
                score: 0))

        return results
    }

    /// Returns a list of member expressions rooted at the given expression that can be written in
    /// the given node.
    private static func memberExpressions(_ root: ExprInfo, in node: Node) -> [ExprInfo] {
        var results: [ExprInfo] = []
        for m in root.type.members(visibleFrom: node) {
            // This checks that method accesses are differentiable wrt self when necessary.
            // TODO: Cleaner way of expressing this that also generalizes to concrete methods.
            if root.varied && m.isMethodMember
                && (
                    !(m as! RequirementNode).signature.differentiableAttribute
                        || !m.containerType.conforms(to: .differentiable)
                )
            {
                continue
            }
            results.append(
                ExprInfo(
                    expr: .member(container: root.expr, member: m),
                    type: m.memberType,
                    varied: root.varied
                        && (m.memberType.conforms(to: .differentiable) || m.isMethodMember),
                    score: root.score + (-10...10).randomElement()!))
        }
        return results
    }

    /// Returns an expression applying 'f' to the earliest allowed 'candidateArgs'.
    ///
    /// If 'f' is not a function or if there are no allowed 'candidateArgs', returns nil.
    private static func applyExpression(f: ExprInfo, candidateArgs: [ExprInfo]) -> ExprInfo? {
        guard case .functionType(let functionType) = f.type else { return nil }

        // TODO: support generic return type
        guard case .concrete(let returnType) = functionType.returnType else { return nil }

        func allowed(_ info: ExprInfo, _ ft: FunctionType, _ fta: FunctionTypeArgument) -> Bool {
            // Forbid passing functions with generic signatures because this often leads to their generic
            // parameters not being inferrable.
            if case .functionType(let functionType) = info.type,
                functionType.genericArguments.count > 0
            {
                return false
            }

            // Forbid declrefs to initializers because Swift doesn't understand that we mean it as a
            // function value.
            if case .declRef(let referencedNode) = info.expr, referencedNode is InitializerNode {
                return false
            }

            switch fta.type {
            case .generic(let index):
                for constraint in ft.genericArguments[index].constraints {
                    if !info.type.conforms(to: constraint) { return false }
                }
            case .concrete(let type):
                if info.type != type { return false }
            }

            if info.varied && !fta.differentiable { return false }

            return true
        }

        var args: [ExprInfo] = []
        for arg in functionType.arguments {
            guard let allowedArg = candidateArgs.first(where: { allowed($0, functionType, arg) })
            else {
                return nil
            }
            args.append(allowedArg)
        }

        return ExprInfo(
            expr: .apply(f: f.expr, args: args.map { $0.expr }),
            type: returnType,
            varied: f.varied || args.contains(where: { $0.varied }),
            score: f.score + args.map { $0.score }.reduce(0, +) + (-10...10).randomElement()!)
    }
}

fileprivate extension Type {
    /// Returns the members of the current type that are visible from the given node.
    func members(visibleFrom viewingNode: Node) -> [MemberDecl] {
        // TODO: Actually calculate visibility.
        // TODO: Probably needs deduplication of results.
        switch self {
        case .structType(let structNode):
            return structNode.children.compactMap { $0 as? FieldNode }
        case .genericArgumentType(let genericArgumentNode):
            return genericArgumentNode.constraints.flatMap {
                Type.protocolSelfType($0).members(visibleFrom: viewingNode)
            }
        case .protocolSelfType(let proto):
            switch proto {
            case .differentiable:
                return []
            case .declared(let protoNode):
                return protoNode.requirements
                    + protoNode.refinements.flatMap {
                        Type.protocolSelfType($0).members(visibleFrom: viewingNode)
                    }
            }
        default:
            return []
        }
    }
}
