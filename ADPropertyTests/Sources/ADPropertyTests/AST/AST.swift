class AST {
    /// The root node of the AST.
    var project: ProjectNode! = nil

    /// All the nodes in the AST.
    var nodes: [Node] = []

    init() {
        self.project = ProjectNode(ast: self)
    }

    /// Return a copy of this AST.
    func copied() -> AST {
        let other = AST()
        for node in nodes.dropFirst() {
            let _ = type(of: node).init(ast: other)
        }
        for (thisNode, otherNode) in zip(nodes, other.nodes) {
            otherNode.copy(from: thisNode)
        }
        return other
    }

    /// Given a node from a copy of this AST, returns the corresponding node in this AST.
    func corresponding<T: Node>(_ node: T) -> T {
        return nodes[node.id] as! T
    }
}
