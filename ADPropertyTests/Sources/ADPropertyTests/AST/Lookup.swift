/// Methods for determining which declarations are visible in various contexts.
extension Node {
    /// Closest ancestor of the given type.
    func ancestor<T: Node>(_ type: T.Type) -> T? {
        if let p = self as? T { return p }
        return parent?.ancestor(type)
    }

    /// All top level decls of the given type visible from this node.
    func visibleTopLevel<T: TopLevelDecl>(_ type: T.Type) -> [T] {
        let currentFileDecls: [T]
        let currentModuleDecls: [T]
        let importedModuleDecls: [T]

        if let currentFile = ancestor(FileNode.self) {
            currentFileDecls = currentFile.allTopLevel(type, withAccessLevelAtLeast: .alPrivate)
            importedModuleDecls = currentFile.imports.flatMap { (module: ModuleNode) -> [T] in
                return module.allTopLevel(type, withAccessLevelAtLeast: .alPublic)
            }
        } else {
            currentFileDecls = []
            importedModuleDecls = []
        }

        if let currentModule = ancestor(ModuleNode.self) {
            currentModuleDecls = currentModule.files.flatMap { (file: FileNode) -> [T] in
                guard file !== ancestor(FileNode.self) else { return [] }
                return file.allTopLevel(type, withAccessLevelAtLeast: .alInternal)
            }
        } else {
            currentModuleDecls = []
        }

        return currentFileDecls + currentModuleDecls + importedModuleDecls
    }

    /// All protocols visible from this node.
    func visibleProtocols() -> [Protocol] {
        Protocol.builtins + visibleTopLevel(ProtocolNode.self).map { .declared($0) }
    }

    /// All nominal types visible from this node.
    func visibleNominalTypes() -> [Type] {
        Type.builtins + visibleTopLevel(StructNode.self).map { .structType($0) }
    }

    /// All decls that can be referenced by a .declRef expression in the current node.
    func referencableDecls() -> [ReferencableDecl] {
        // TODO: Update this when we add new relevant types of nodes to the AST.
        var result: [ReferencableDecl] = []
        if let p = ancestor(InitializerNode.self) { result += p.signature.arguments }
        if let p = ancestor(FunctionNode.self) { result += p.signature.arguments }
        result += visibleTopLevel(FunctionNode.self)
        for s in visibleTopLevel(StructNode.self) {
            result += s.children.compactMap { $0 as? InitializerNode }
        }
        return result
    }
}

extension ModuleNode {
    /// All top level decls of the given type in this module.
    func allTopLevel<T: TopLevelDecl>(
        _ type: T.Type, withAccessLevelAtLeast level: AccessLevel
    ) -> [T] {
        files.flatMap { $0.allTopLevel(type, withAccessLevelAtLeast: level) }
    }
}

extension FileNode {
    /// All top level decls of the given type in this file.
    func allTopLevel<T: TopLevelDecl>(
        _ type: T.Type, withAccessLevelAtLeast level: AccessLevel
    ) -> [T] {
        children.compactMap {
            guard let t = $0 as? T, t.accessLevel >= level else { return nil }
            return t
        }
    }
}
