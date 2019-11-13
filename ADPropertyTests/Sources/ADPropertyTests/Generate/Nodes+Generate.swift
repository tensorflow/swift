/// Methods for randomly generating AST nodes.
///
/// To generate an AST node, you typically construct a blank AST node of the desired type, link it
/// into the AST in the desired location, and then call its `generate` method, which randomly
/// populates its properties and child nodes. The `generate` methods typically generate their child
/// nodes this way too.

extension ProjectNode {
    func generate(_ conf: GeneratorConfiguration) {
        for _ in 0..<conf.modulesPerProject {
            let module = ModuleNode(ast: ast, parent: self)
            modules.append(module)
            module.generate(conf)
        }
    }
}

extension ModuleNode {
    func generate(_ conf: GeneratorConfiguration) {
        for _ in 0..<conf.filesPerModule {
            let file = FileNode(ast: ast, parent: self)
            files.append(file)
            file.generate(conf)
        }
    }
}

extension FileNode {
    func generate(_ conf: GeneratorConfiguration) {
        for _ in randomRangeUpTo(conf.importsPerFile) {
            guard
                let module = ast.project.modules.arbitrary(
                    not: imports + [ancestor(ModuleNode.self)].compactMap { $0 })
            else {
                continue
            }
            imports.append(module)
        }

        for _ in 0..<conf.protocolsPerFile {
            let protocolNode = ProtocolNode(ast: ast, parent: self)
            children.append(protocolNode)
            protocolNode.generate(conf)
        }
        for _ in 0..<conf.structsPerFile {
            let structNode = StructNode(ast: ast, parent: self)
            children.append(structNode)
            structNode.generate(conf)
        }
        for _ in 0..<conf.functionsPerFile {
            let functionNode = FunctionNode(ast: ast, parent: self)
            children.append(functionNode)
            functionNode.generate(conf)
        }
    }
}

extension ProtocolNode {
    func generate(_ conf: GeneratorConfiguration) {
        for _ in randomRangeUpTo(conf.refinementsPerProtocol) {
            guard let refinement = visibleProtocols().arbitrary(not: .declared(self)) else {
                continue
            }
            refinements.append(refinement)
        }

        for _ in 0..<conf.requirementsPerProtocol {
            let requirementNode = RequirementNode(ast: ast, parent: self)
            requirements.append(requirementNode)
            requirementNode.generate(conf)
        }

        // Add a default implementation of all the requirements.
        // TODO: Make it so that there aren't always default implementations of all the requirements.
        let parentFile = ancestor(FileNode.self)!
        let defaultImplementationExtension = ExtensionNode(ast: ast, parent: parentFile)
        parentFile.children.append(defaultImplementationExtension)
        defaultImplementationExtension.extends = self
        for requirement in requirements {
            let functionNode = FunctionNode(ast: ast, parent: defaultImplementationExtension)
            defaultImplementationExtension.children.append(functionNode)
            functionNode.generateImplementation(of: requirement, conf)
        }
    }
}

extension RequirementNode {
    func generate(_ conf: GeneratorConfiguration) {
        signature = SignatureNode(ast: ast, parent: self)
        signature.generate(conf)
    }
}

extension SignatureNode {
    func generate(_ conf: GeneratorConfiguration) {
        for _ in randomRangeUpTo(conf.genericArgumentsPerFunction) {
            let genericArgument = GenericArgumentNode(ast: ast, parent: self)
            genericArguments.append(genericArgument)
            for _ in randomRangeUpTo(conf.constraintsPerGenericArgument) {
                guard
                    let constraint = visibleProtocols().arbitrary(not: genericArgument.constraints)
                else {
                    continue
                }
                genericArgument.constraints.append(constraint)
            }
        }

        let possibleTypes = visibleNominalTypes()
            + genericArguments.map { .genericArgumentType($0) }
        for _ in randomRangeUpTo(conf.argumentsPerFunction) {
            guard let type = possibleTypes.arbitrary() else { continue }
            let argumentNode = ArgumentNode(ast: ast, parent: self)
            arguments.append(argumentNode)
            argumentNode.type = type
        }

        // Ensure that all generic arguments are used in the signature.
        for genericArgument in genericArguments {
            guard !arguments.contains(where: { $0.type == .genericArgumentType(genericArgument) })
            else {
                continue
            }
            let argumentNode = ArgumentNode(ast: ast, parent: self)
            arguments.append(argumentNode)
            argumentNode.type = .genericArgumentType(genericArgument)
        }

        returnType = .float

        // Randomly add @differentiable attribute, if it's allowed.
        if arguments.contains(where: { $0.type.conforms(to: .differentiable) })
            && decideDifferentiable()
        {
            differentiableAttribute = true
        }
    }
}

extension StructNode {
    func generate(_ conf: GeneratorConfiguration) {
        for _ in randomRangeUpTo(conf.conformancesPerStruct) {
            guard let conformance = visibleProtocols().arbitrary(not: conformances) else {
                continue
            }
            conformances.append(conformance)
        }

        for _ in 0..<conf.fieldsPerStruct {
            let fieldNode = FieldNode(ast: ast, parent: self)
            children.append(fieldNode)
            fieldNode.generate(conf)
        }

        noArgumentInit = InitializerNode(ast: ast, parent: self)
        children.append(noArgumentInit)
        noArgumentInit.generateNoArgumentInitialzer(conf)

        fullArgumentInit = InitializerNode(ast: ast, parent: self)
        children.append(fullArgumentInit)
        fullArgumentInit.generateFullArgumentInitializer(conf)
    }
}

extension InitializerNode {
    /// Generates initializer that takes no arguments.
    func generateNoArgumentInitialzer(_ conf: GeneratorConfiguration) {
        let parentStruct = parent as! StructNode
        signature = SignatureNode(ast: ast, parent: self)
        signature.isInitializer = true
        signature.returnType = .structType(parentStruct)
        for field in parentStruct.children.compactMap({ $0 as? FieldNode }) {
            let initialValueExpr = ExprNode(ast: ast, parent: self)
            initialValueExpr.expr = Expr(simplestWithType: field.type)
            initialValues.append((field, initialValueExpr))
        }
    }

    /// Generates initializer that takes one argument per field.
    func generateFullArgumentInitializer(_ conf: GeneratorConfiguration) {
        let parentStruct = parent as! StructNode
        signature = SignatureNode(ast: ast, parent: self)
        signature.isInitializer = true
        signature.returnType = .structType(parentStruct)
        for field in parentStruct.children.compactMap({ $0 as? FieldNode }) {
            let initialValueArg = ArgumentNode(ast: ast, parent: signature)
            signature.arguments.append(initialValueArg)
            initialValueArg.type = field.type

            let initialValueExpr = ExprNode(ast: ast, parent: self)
            initialValueExpr.expr = .declRef(initialValueArg)
            initialValues.append((field, initialValueExpr))
        }

        // Randomly add @differentiable attribute, if it's allowed.
        if Type.structType(parentStruct).conforms(to: .differentiable)
            && signature.arguments.contains(where: { $0.type.conforms(to: .differentiable) })
            && decideDifferentiable()
        {
            signature.differentiableAttribute = true
        }
    }
}

extension FieldNode {
    func generate(_ conf: GeneratorConfiguration) {
        let parentStruct = parent as! StructNode
        type = visibleNominalTypes().arbitrary(not: .structType(parentStruct))!
    }
}

extension FunctionNode {
    func generate(_ conf: GeneratorConfiguration) {
        signature = SignatureNode(ast: ast, parent: self)
        signature.generate(conf)

        block = CodeBlockNode(ast: ast, parent: self)
        block.generate(conf)
    }

    func generateImplementation(of requirement: RequirementNode, _ conf: GeneratorConfiguration) {
        signature = requirement.signature
        satisfies = requirement

        block = CodeBlockNode(ast: ast, parent: self)
        block.generate(conf)
    }
}

extension CodeBlockNode {
    func generate(_ conf: GeneratorConfiguration) {
        let returnStatement = ReturnStatementNode(ast: ast, parent: self)
        statements.append(returnStatement)
        returnStatement.expr = ExprNode(ast: ast, parent: returnStatement)
        returnStatement.expr.expr = Expr(randomWithType: .float, in: self, conf: conf)
    }
}

// MARK: - Useful utilities.

fileprivate func randomRangeUpTo(_ count: Int) -> Range<Int> {
    return 0..<((0...count).randomElement()!)
}

fileprivate extension Array where Element: Equatable {
    func arbitrary() -> Element? {
        return randomElement()
    }

    func arbitrary(not excludedElement: Element?) -> Element? {
        if let e = randomElement(), e != excludedElement { return e }
        return filter { $0 != excludedElement }.randomElement()
    }

    func arbitrary(not excludedElements: [Element]) -> Element? {
        if let e = randomElement(), !excludedElements.contains(e) { return e }
        return filter { !excludedElements.contains($0) }.randomElement()
    }
}

fileprivate func decideDifferentiable() -> Bool {
    return (0..<5).randomElement() != 0
}
