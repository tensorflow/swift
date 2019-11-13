enum Protocol: Equatable, Hashable {
    case differentiable
    case declared(ProtocolNode)

    static let builtins: [Protocol] = [.differentiable]
}

extension Protocol: CustomStringConvertible {
    var description: String {
        switch self {
        case .differentiable:
            return "Differentiable"
        case .declared(let node):
            return "\(node)"
        }
    }
}

extension AST {
    /// Given a protocol in a copy of this AST, returns the corresponding protocol in this AST.
    func corresponding(_ p: Protocol) -> Protocol {
        switch (p) {
        case .differentiable:
            return .differentiable
        case .declared(let node):
            return .declared(corresponding(node))
        }
    }
}
