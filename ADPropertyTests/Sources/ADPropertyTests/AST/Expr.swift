indirect enum Expr {
    case floatLiteral(String)
    case intLiteral(String)
    case declRef(Node)
    case apply(f: Expr, args: [Expr])
    case member(container: Expr, member: Node)
}

extension Expr {
    var code: String {
        switch (self) {
        case .floatLiteral(let s):
            return s
        case .intLiteral(let s):
            return s
        case .declRef(let node):
            return "\(node)"
        case .apply(f: let f, args: let args):
            return "\(f.code)(\(args.map { "\($0.code)" }.joined(separator: ", ")))"
        case .member(container: let container, member: let member):
            return "\(container.code).\(member)"
        }
    }
}

extension AST {
    /// Given an expression in a copy of this AST, retutrns the corresponding expression in this AST.
    func corresponding(_ expr: Expr) -> Expr {
        switch (expr) {
        case .floatLiteral(let s):
            return .floatLiteral(s)
        case .intLiteral(let s):
            return .intLiteral(s)
        case .declRef(let node):
            return .declRef(corresponding(node))
        case .apply(f: let f, args: let args):
            return .apply(f: corresponding(f), args: args.map(corresponding))
        case .member(container: let container, member: let member):
            return .member(container: corresponding(container), member: corresponding(member))
        }
    }
}
