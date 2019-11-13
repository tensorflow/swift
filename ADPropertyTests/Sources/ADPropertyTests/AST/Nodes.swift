// MARK: - Node base class.

class Node: CustomStringConvertible {
    /// AST that contains this node.
    let ast: AST

    /// Unique identifier for this node within its AST.
    let id: Int

    /// The node's parent.
    var parent: Node? = nil

    /// Creates a blank node within the given AST.
    required init(ast: AST) {
        self.ast = ast
        self.id = ast.nodes.count
        ast.nodes.append(self)
    }

    /// Creates a blank node within the given AST and sets its parent.
    convenience init(ast: AST, parent: Node) {
        self.init(ast: ast)
        self.parent = parent
    }

    /// The string that you use to reference this node in the code.
    var description: String {
        var idString = "\(id)"
        let padTo = 5
        if idString.count < padTo {
            idString = String(repeating: "0", count: padTo - idString.count) + idString
        }
        return "\(Self.prefix)\(idString)\(Self.suffix)"
    }

    /// Copies all node properties from the other node.
    func copy(from otherNode: Node) {
        parent = ast.corresponding(otherNode)
    }

    /// Prefix for the description of the node.
    class var prefix: String { "" }

    /// Suffix for the description of the node.
    class var suffix: String { "" }

    /// The string that implements this node in the code.
    var code: String { "" }
}

extension Node: Equatable, Hashable {
    static func == (lhs: Node, rhs: Node) -> Bool { lhs === rhs }
    func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self).hash(into: &hasher)
    }
}

// MARK: - Protocols categorizing nodes with certain properties.

/// This node can appear as a top level declaration in a file.
protocol TopLevelDecl: Node {
    var accessLevel: AccessLevel { get }
}

/// Declares a member of a type.
protocol MemberDecl: Node {
    /// The type the container.
    var containerType: Type { get }

    /// The type of the declared member.
    var memberType: Type { get }

    /// Whether this member is a method.
    var isMethodMember: Bool { get }
}

/// A decl that can be referened by a .declRef expression.
protocol ReferencableDecl: Node {
    /// The type of the .declRef expression.
    var declRefType: Type { get }
}

// MARK: - Concrete node types.

final class ProjectNode: Node {
    override class var prefix: String { "Project" }

    var modules: [ModuleNode] = []

    override func copy(from otherNode: Node) {
        let otherNode = otherNode as! Self
        modules = otherNode.modules.map(ast.corresponding)
        super.copy(from: otherNode)
    }

    override var code: String {
        modules.map {
            "=== \($0) ===\n" + "\($0.code)\n"
        }.joined()
    }
}

final class ModuleNode: Node {
    override class var prefix: String { "Module" }

    var files: [FileNode] = []

    override func copy(from otherNode: Node) {
        let otherNode = otherNode as! Self
        files = otherNode.files.map(ast.corresponding)
        super.copy(from: otherNode)
    }

    override var code: String {
        files.map {
            "\($0):\n" + "\($0.code)\n"
        }.joined()
    }
}

final class FileNode: Node {
    override class var prefix: String { "file" }
    override class var suffix: String { ".swift" }

    var imports: [ModuleNode] = []
    var children: [Node] = []

    override func copy(from otherNode: Node) {
        let otherNode = otherNode as! Self
        imports = otherNode.imports.map(ast.corresponding)
        children = otherNode.children.map(ast.corresponding)
        super.copy(from: otherNode)
    }

    override var code: String {
        imports.map { "import \($0)\n" }.joined() + "\n" + children.joinedCode
    }
}

final class ProtocolNode: Node, TopLevelDecl {
    override class var prefix: String { "Protocol" }

    var accessLevel: AccessLevel = .alPublic
    var refinements: [Protocol] = []
    var requirements: [RequirementNode] = []

    override func copy(from otherNode: Node) {
        let otherNode = otherNode as! Self
        accessLevel = otherNode.accessLevel
        refinements = otherNode.refinements.map(ast.corresponding)
        requirements = otherNode.requirements.map(ast.corresponding)
        super.copy(from: otherNode)
    }

    override var code: String {
        "\(accessLevel) protocol \(self)\(refinements.constraintCode) {\n"
            + requirements.indentedCode + "}\n"
    }
}

final class RequirementNode: Node, MemberDecl {
    override class var prefix: String { "requirement" }

    var signature: SignatureNode! = nil

    override func copy(from otherNode: Node) {
        let otherNode = otherNode as! Self
        signature = ast.corresponding(otherNode.signature)
        super.copy(from: otherNode)
    }

    override var code: String {
        "\(signature.attributesCode)func \(self)\(signature.code)\n"
    }

    var containerType: Type {
        .protocolSelfType(.declared(parent as! ProtocolNode))
    }

    var memberType: Type {
        // TODO: This calculation handles protocol self type incorrectly.
        .functionType(FunctionType(signature))
    }

    var isMethodMember: Bool { true }
}

final class SignatureNode: Node {
    override class var prefix: String { "signature" }

    var genericArguments: [GenericArgumentNode] = []
    var arguments: [ArgumentNode] = []
    var returnType: Type! = nil
    var isInitializer: Bool = false
    var differentiableAttribute: Bool = false

    override func copy(from otherNode: Node) {
        let otherNode = otherNode as! Self
        genericArguments = otherNode.genericArguments.map(ast.corresponding)
        arguments = otherNode.arguments.map(ast.corresponding)
        super.copy(from: otherNode)
    }

    var attributesCode: String {
        if differentiableAttribute {
            return "@differentiable\n"
        } else {
            return ""
        }
    }

    var genericSignatureCode: String {
        guard genericArguments.count > 0 else { return "" }
        return "<" + genericArguments.listCode + ">"
    }

    var argumentListCode: String {
        "(" + arguments.listCode + ")"
    }

    var returnTypeCode: String {
        if isInitializer { return "" }
        return " -> Float"
    }

    override var code: String {
        "\(genericSignatureCode)\(argumentListCode)\(returnTypeCode)"
    }
}

final class GenericArgumentNode: Node {
    override class var prefix: String { "T" }

    var constraints: [Protocol] = []

    override func copy(from otherNode: Node) {
        let otherNode = otherNode as! Self
        constraints = otherNode.constraints.map(ast.corresponding)
        super.copy(from: otherNode)
    }

    override var code: String {
        "\(self)\(constraints.constraintCode)"
    }
}

final class ArgumentNode: Node, ReferencableDecl {
    override class var prefix: String { "arg" }

    var type: Type! = nil

    override func copy(from otherNode: Node) {
        let otherNode = otherNode as! Self
        type = ast.corresponding(otherNode.type)
        super.copy(from: otherNode)
    }

    override var code: String {
        "_ \(self): \(type!)"
    }

    var declRefType: Type { type }
}

final class StructNode: Node, TopLevelDecl {
    override class var prefix: String { "Struct" }

    var accessLevel: AccessLevel = .alPublic
    var conformances: [Protocol] = []
    var children: [Node] = []

    var noArgumentInit: InitializerNode!
    var fullArgumentInit: InitializerNode!

    override func copy(from otherNode: Node) {
        let otherNode = otherNode as! Self
        accessLevel = otherNode.accessLevel
        conformances = otherNode.conformances.map(ast.corresponding)
        children = otherNode.children.map(ast.corresponding)
        super.copy(from: otherNode)
    }

    override var code: String {
        "\(accessLevel) struct \(self)\(conformances.constraintCode) {\n" + children.indentedCode
            + "}\n"
    }
}

final class InitializerNode: Node, ReferencableDecl {
    override class var prefix: String { "init" }

    var signature: SignatureNode! = nil
    var accessLevel: AccessLevel = .alPublic
    var initialValues: [(FieldNode, ExprNode)] = []

    override func copy(from otherNode: Node) {
        let otherNode = otherNode as! Self
        signature = ast.corresponding(signature)
        accessLevel = otherNode.accessLevel
        initialValues = otherNode.initialValues.map {
            (ast.corresponding($0.0), ast.corresponding($0.1))
        }
        super.copy(from: otherNode)
    }

    override var code: String {
        "\(signature.attributesCode)\(accessLevel) init\(signature.code) {\n"
            + initialValues.map {
                "self.\($0.0) = \($0.1.code)\n"
            }.joined().indented(by: 1) + "}\n"
    }

    override var description: String {
        "\(parent!)"
    }

    var declRefType: Type { .functionType(FunctionType(signature)) }
}

final class FieldNode: Node, MemberDecl {
    override class var prefix: String { "field" }

    var accessLevel: AccessLevel = .alPublic
    var type: Type! = nil

    override func copy(from otherNode: Node) {
        let otherNode = otherNode as! Self
        accessLevel = otherNode.accessLevel
        type = ast.corresponding(otherNode.type)
        super.copy(from: otherNode)
    }

    override var code: String {
        "\(accessLevel) var \(self): \(type!)\n"
    }

    var containerType: Type { .structType(parent as! StructNode) }

    var memberType: Type { type }

    var isMethodMember: Bool { false }
}

final class FunctionNode: Node, TopLevelDecl, ReferencableDecl {
    override class var prefix: String { "function" }

    var accessLevel: AccessLevel = .alPublic
    var satisfies: RequirementNode? = nil
    var signature: SignatureNode! = nil
    var block: CodeBlockNode! = nil

    override func copy(from otherNode: Node) {
        let otherNode = otherNode as! Self
        accessLevel = otherNode.accessLevel
        satisfies = otherNode.satisfies.map(ast.corresponding)
        signature = ast.corresponding(otherNode.signature)
        block = ast.corresponding(otherNode.block)
        super.copy(from: otherNode)
    }

    override var description: String {
        if let satisfies = satisfies { return "\(satisfies)" }
        return super.description
    }

    override var code: String {
        "\(signature.attributesCode)\(accessLevel) func \(self)\(signature.code) {\n\(block.code.indented(by: 1))}\n"
    }

    var declRefType: Type { .functionType(FunctionType(signature)) }
}

final class ExtensionNode: Node, TopLevelDecl {
    override class var prefix: String { "Extension" }

    var accessLevel: AccessLevel = .alPublic
    var extends: Node! = nil
    var children: [Node] = []

    override func copy(from otherNode: Node) {
        let otherNode = otherNode as! Self
        accessLevel = otherNode.accessLevel
        extends = ast.corresponding(otherNode.extends)
        children = otherNode.children.map(ast.corresponding)
        super.copy(from: otherNode)
    }

    override var code: String {
        "\(accessLevel) extension \(extends!) {\n\(children.indentedCode)}\n"
    }
}

final class CodeBlockNode: Node {
    override class var prefix: String { "Block" }

    var statements: [Node] = []

    override func copy(from otherNode: Node) {
        let otherNode = otherNode as! Self
        statements = otherNode.statements.map(ast.corresponding)
        super.copy(from: otherNode)
    }

    override var code: String {
        statements.joinedCode
    }
}

final class ReturnStatementNode: Node {
    override class var prefix: String { "return" }

    var expr: ExprNode! = nil

    override func copy(from otherNode: Node) {
        let otherNode = otherNode as! Self
        expr = ast.corresponding(otherNode.expr)
        super.copy(from: otherNode)
    }

    override var code: String {
        "return \(expr.code)\n"
    }
}

final class ExprNode: Node {
    override class var prefix: String { "expr" }

    var expr: Expr! = nil

    override func copy(from otherNode: Node) {
        let otherNode = otherNode as! Self
        expr = ast.corresponding(otherNode.expr)
        super.copy(from: otherNode)
    }

    override var code: String { expr.code }
}

// MARK: - Code formatting utilities.

fileprivate extension String {
    func indented(by amount: Int) -> String {
        let spacesPerIndent = 2
        return split(separator: "\n", omittingEmptySubsequences: false)
            .map {
                if $0.count > 0 {
                    return String(repeating: " ", count: spacesPerIndent * amount) + $0
                } else {
                    return String($0)
                }
            }
            .joined(separator: "\n")
    }
}

fileprivate extension Array where Element: Node {
    var joinedCode: String {
        map { $0.code }.joined()
    }

    var indentedCode: String {
        map { $0.code }.joined().indented(by: 1)
    }

    var listCode: String {
        map { $0.code }.joined(separator: ", ")
    }
}

fileprivate extension Array where Element == Protocol {
    var constraintCode: String {
        if count == 0 {
            return ""
        } else {
            return ": " + map { "\($0)" }.joined(separator: ", ")
        }
    }
}
