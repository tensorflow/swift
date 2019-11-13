indirect enum Type: Equatable, Hashable {
    case float
    case int
    case structType(StructNode)
    case genericArgumentType(GenericArgumentNode)
    case protocolSelfType(Protocol)
    case functionType(FunctionType)

    static let builtins: [Type] = [.float, .int]
}

extension Type: CustomStringConvertible {
    var description: String {
        switch self {
        case .float:
            return "Float"
        case .int:
            return "Int"
        case .structType(let node):
            return "\(node)"
        case .genericArgumentType(let node):
            return "\(node)"
        case .protocolSelfType(_), .functionType(_):
            fatalError("unimplemented type description")
        }
    }
}

extension AST {
    /// Given a type in a copy of this AST, returns the corresponding type in this AST.
    func corresponding(_ t: Type) -> Type {
        switch (t) {
        case .float:
            return .float
        case .int:
            return .int
        case .structType(let node):
            return .structType(corresponding(node))
        case .genericArgumentType(let node):
            return .genericArgumentType(corresponding(node))
        case .protocolSelfType(let node):
            return .protocolSelfType(node)
        case .functionType(let ft):
            return .functionType(corresponding(ft))
        }
    }

    private func corresponding(_ ft: FunctionType) -> FunctionType {
        FunctionType(
            genericArguments: ft.genericArguments.map(corresponding),
            arguments: ft.arguments.map(corresponding),
            returnType: corresponding(ft.returnType))
    }

    private func corresponding(_ fta: FunctionTypeArgument) -> FunctionTypeArgument {
        FunctionTypeArgument(
            type: corresponding(fta.type),
            differentiable: fta.differentiable)
    }

    private func corresponding(_ ftat: FunctionTypeType) -> FunctionTypeType {
        switch ftat {
        case .generic(let index):
            return .generic(index)
        case .concrete(let type):
            return .concrete(corresponding(type))
        }
    }

    private func corresponding(_ ga: FunctionTypeGenericArgument) -> FunctionTypeGenericArgument {
        FunctionTypeGenericArgument(constraints: ga.constraints.map(corresponding))
    }
}

// MARK: - FunctionType.

struct FunctionType: Equatable, Hashable {
    var genericArguments: [FunctionTypeGenericArgument]
    var arguments: [FunctionTypeArgument]
    var returnType: FunctionTypeType
}

struct FunctionTypeArgument: Equatable, Hashable {
    var type: FunctionTypeType
    var differentiable: Bool
}

enum FunctionTypeType: Equatable, Hashable {
    case generic(Int)
    case concrete(Type)
}

struct FunctionTypeGenericArgument: Equatable, Hashable {
    var constraints: [Protocol]
}

extension FunctionType {
    init(_ signature: SignatureNode) {
        var genericArgumentIndices: [GenericArgumentNode: Int] = [:]
        genericArguments = signature.genericArguments.enumerated().map {
            genericArgumentIndices[$0.element] = $0.offset
            return FunctionTypeGenericArgument(constraints: $0.element.constraints)
        }

        func functionTypeType(_ type: Type) -> FunctionTypeType {
            switch type {
            case .genericArgumentType(let genericArgumentNode):
                return .generic(genericArgumentIndices[genericArgumentNode]!)
            case .protocolSelfType(_):
                fatalError("protocolSelfType unimplemented")
            default:
                return .concrete(type)
            }
        }

        arguments = signature.arguments.map {
            FunctionTypeArgument(
                type: functionTypeType($0.type),
                differentiable: signature.differentiableAttribute
                    && $0.type.conforms(to: .differentiable))
        }

        returnType = functionTypeType(signature.returnType)
    }
}

// MARK: - Type queries.

extension Type {
    func conforms(to queryProto: Protocol) -> Bool {
        switch self {
        case .float:
            return queryProto == .differentiable
        case .int:
            return false
        case .structType(let node):
            return node.conformances.contains(
                where: { Type.protocolSelfType($0).conforms(to: queryProto) })
        case .genericArgumentType(let node):
            return node.constraints.contains(
                where: { Type.protocolSelfType($0).conforms(to: queryProto) })
        case .protocolSelfType(let proto):
            if proto == queryProto { return true }
            switch proto {
            case .differentiable:
                return false
            case .declared(let node):
                return node.refinements.contains(
                    where: { Type.protocolSelfType($0).conforms(to: queryProto) })
            }
        case .functionType(_):
            return false
        }
    }
}
