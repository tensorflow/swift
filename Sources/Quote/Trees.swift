// Copyright 2019 The TensorFlow Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// `Tree` models abstract syntax trees that represent the supported subset of Swift
/// At the moment, this subset isn't particularly rich, but we are planning to extend it over
/// time until it eventually covers the entire language.
///
/// Trees can be constructed either manually or via #quote(...). When applicable, the latter may be
/// preferable because it's much more concise. (In the examples below, we'll be using a REPL-like
/// notation where lines that start with > indicate Swift code and other lines stand for program
/// output):
///
///     > let fourtyTwo: Quote<Int> = #quote(42)
///     > print(fourtyTwo.expression)
///     42
///
///     > let fourtyTwoAgain = IntegerLiteral(42, TypeName("Int", ...))
///     > print(fourtyTwoAgain)
///     42
///
/// Trees can deconstructed via downcasting. In Swift, only enums support ML-like pattern matching.
/// However, enums come with certain limitations, so our trees are not enums and therefore don't
/// enjoy the full benefits of pattern matching. In the future, we may consider extending Swift
/// pattern matching to support protocols, classes and structures, but that's a long shot.
///
///     > if let lit = fourtyTwo.expression as? IntegerLiteral {
///     >   print(lit.value)
///     > }
///     42
///
///     > switch fourtyTwo.expression {
///     >   case let lit as IntegerLiteral:
///     >     print(lit.value)
///     >   default:
///     >     print("not a literal")
///     > }
///     42
///
/// At the moment, we don't have documentation for which language feature correspond to which
/// tree structures (#25), so the only way to figure that out is to experiment with quoting
/// the code that you're curious about and inspecting its structure via `Tree.structure`.
///
/// Our trees carry semantic information, including symbols and types, which means that they
/// don't fully correspond to parse trees. There are some details in original syntax that are
/// not present in our trees (e.g. comments, whitespace, presence or absense of type annotations,
/// among others). There are also some details in our trees that are not present in original syntax
/// (e.g. inferred types, vararg / default arguments, among others).
///
/// Symbols, available in trees that create or reference declarations, are string-based identifiers
/// for declarations. The idea is that these identifiers are unique across globally visible
/// declarations, and are unique across local declarations within the same file. For that purpose,
/// we're using unified symbol resolutions (USRs) available in the Swift compiler.
///
///     > let def = 42
///     > let ref = #quote(def)
///     > if let name = ref.expression as? Name {
///     >   print(name.symbol)
///     > }
///     s:4main3defSivp
///
/// At the moment, we don't have docs for which definition have which symbols (#26).
/// In order to figure that out you may: 1) quote the corresponding code and manually inspecting
/// symbols, or 2) ask `sourcekitd-test` to obtain a USR at a given position in a given file:
///
///     $ cat test.swift
///     let x: Int = 42
///
///     $ sourcekitd-test -print-raw-response -req=cursor -pos=1:10 $(pwd)/test.swift -- $(pwd)/test.swift
///     {
///       key.request: source.request.cursorinfo,
///       key.compilerargs: [
///         "/Users/burmako/scratchpad/test.swift"
///       ],
///       key.offset: 9,
///       key.sourcefile: "/Users/burmako/scratchpad/test.swift"
///     }
///     {
///       key.kind: source.lang.swift.ref.struct,
///       key.name: "Int",
///       key.usr: "s:Si",
///       ...
///     }
///
/// Quotes are an early work in progress, so it is expected that there are lots of bugs and missing
/// features. At https://bugs.swift.org/browse/TF, you can find the list of known issues. Please
/// consider reporting issues as you encounter them.
public protocol Tree: CustomStringConvertible {
}

/// Tree that represents an unsupported language construct.
/// At the moment, our trees only represent a modest subset of Swift, so this tree may be a
/// frequent guest in quotes. In the future, we are planning to extend the supported subset of
/// the language until it eventually covers everything.
public class UnknownTree: Attribute, Type, Condition, Statement, Expression, Declaration {
    public var type: Type {
        return UnknownTree()
    }

    public init() {
    }
}

// MARK: Attributes

/// Tree that represents a Swift attribute.
public protocol Attribute: Tree {
}

/// Tree that represents a @differentiable attribute.
///
///     > let foo: @differentiable (Float) -> Float = { x in x }
///     > let q = #quote(foo)
///     > print(q.type.structure)
///     FunctionType(
///       [Differentiable()],
///       [TypeName("Float", "s:Sf")],
///       TypeName("Float", "s:Sf"))
public class Differentiable: Attribute {
    public init() {
    }
}

// MARK: Types

/// Tree that represents a Swift type - either explicitly written down by the programmers or
/// inferred by the compiler.
public protocol Type: Tree {
}

/// Tree that represents a protocol composition type.
/// It looks like the Swift compiler represents `Any` with `AnyType([])`.
///
///     > protocol A {}
///     > protocol B {}
///     > func f() -> A & B { fatalError("implement me"); }
///     > let q = #quote(f())
///     > print(q.type.structure)
///     AndType(
///       [TypeName("A", "s:4main1AP"),
///       TypeName("B", "s:4main1BP")])
public class AndType: Type {
    public let types: [Type]

    public init(_ types: [Type]) {
        self.types = types
    }
}

/// Tree that represents an array type [T].
///
///     > let x = [1, 2, 3]
///     > let q = #quote(x)
///     > print(q.type.structure)
///     ArrayType(
///       TypeName("Int", "s:Si"))
public class ArrayType: Type {
    public let type: Type

    public init(_ type: Type) {
        self.type = type
    }
}

/// Tree that represents a dictionary type [T: U].
///
///     > let x = [40: 2]
///     > let q = #quote(x)
///     > print(q.type.structure)
///     DictionaryType(
///       TypeName("Int", "s:Si"),
///       TypeName("Int", "s:Si"))
public class DictionaryType: Type {
    public let key: Type
    public let value: Type

    public init(_ key: Type, _ value: Type) {
        self.key = key
        self.value = value
    }
}

/// Tree that represents a function type (T1, ..., Tn) -> R.
///
///     > let x = { (x: Int) in x }
///     > let q = #quote(x)
///     > print(q.type.structure)
///     FunctionType(
///       [],
///       [TypeName("Int", "s:Si")],
///       TypeName("Int", "s:Si"))
public class FunctionType: Type {
    public let attributes: [Attribute]
    public let parameters: [Type]
    public let result: Type

    public init(_ attributes: [Attribute], _ parameters: [Type], _ result: Type) {
        self.attributes = attributes
        self.parameters = parameters
        self.result = result
    }
}

/// Tree that represents a type of an inout parameter.
///
///     > let q = #quote { (x: inout Int) in x }
///     > print(q.type.structure)
///     FunctionType(
///       [],
///       [InoutType(
///         TypeName("Int", "s:Si"))],
///       TypeName("Int", "s:Si"))
public class InoutType: Type {
    public let type: Type

    public init(_ type: Type) {
        self.type = type
    }
}

/// Tree that represents a type of a reference to an in-out parameter.
///
///     > func foo(_ x: inout Int) {
///     >   let q = #quote { let y = x }
///     >   print(q.type.structure)
///     > }
///     > var x = 2
///     > foo(&x)
///     Closure(
///       [],
///       [Let(
///         Name(
///           "y",
///           "s:4main3fooyySizFyycfU_1yL_Sivp",
///           TypeName("Int", "s:Si")),
///         Conversion(
///           Name(
///             "x",
///             "s:4main3fooyySizF1xL_Sivp",
///             LValueType(
///               TypeName("Int", "s:Si")))))],
///       FunctionType(
///         [],
///         [],
///         TupleType(
///           [])))
public class LValueType: Type {
    public let type: Type

    public init(_ type: Type) {
        self.type = type
    }
}

/// Tree that represents a metatype T.Type or T.Protocol.
///
///     > let x = Int.self
///     > let q = #quote(x)
///     > print(q.type.structure)
///     MetaType(
///       TypeName("Int", "s:Si"))
public class MetaType: Type {
    public let type: Type

    public init(_ type: Type) {
        self.type = type
    }
}

/// Tree that represents an optional type T?.
///
///     > let x: Int? = 42
///     > let q = #quote(x)
///     > print(q.type.structure)
///     OptionalType(
///       TypeName("Int", "s:Si"))
public class OptionalType: Type {
    public let type: Type

    public init(_ type: Type) {
        self.type = type
    }
}

/// Tree that represents a specialized type, i.e. a generic type with generic arguments.
///
///     > let x: ClosedRange<Int> = 1...10
///     > let q = #quote(x)
///     > print(q.type.structure)
///     SpecializedType(
///       TypeName("ClosedRange", "s:SN"),
///       [TypeName("Int", "s:Si")])
public class SpecializedType: Type {
    public let type: Type
    public let arguments: [Type]

    public init(_ type: Type, _ arguments: [Type]) {
        self.type = type
        self.arguments = arguments
    }
}

/// Tree that represents a tuple type (T1, ..., Tn)
///
///     > let x = (1, "2", 3)
///     > let q = #quote(x)
///     > print(q.type.structure)
///     TupleType(
///       [TypeName("Int", "s:Si"),
///       TypeName("String", "s:SS"),
///       TypeName("Int", "s:Si")])
public class TupleType: Type {
    public let types: [Type]

    public init(_ types: [Type]) {
        self.types = types
    }
}

/// Tree that represents a reference to a class, struct, protocol, etc.
///
///    > let x = 42
///    > let q = #quote(x)
///    > print(q.type.structure)
///    TypeName("Int", "s:Si")
public class TypeName: Type {
    public let value: String
    public let symbol: String

    public init(_ value: String, _ symbol: String) {
        self.value = value
        self.symbol = symbol
    }
}

// MARK: Conditions

/// Tree that represents a condition of if, while, repeat, etc.
public protocol Condition: Tree {
}

// MARK: Statements

/// Tree that represents a Swift statement.
public protocol Statement: Tree {
}

/// Tree that represents a break statement.
///
///     > let q = #quote {
///     >   while true {
///     >     break
///     >   }
///     > }
///     > print(q.structure)
///     Closure(
///       [],
///       [While(
///         nil,
///         [BooleanLiteral(
///           true,
///           TypeName("Bool", "s:Sb"))],
///         [Break(
///            nil)])],
///       FunctionType(
///         [],
///         [],
///         TupleType(
///           [])))
public class Break: Statement {
    public let label: String?

    public init(_ label: String?) {
        self.label = label
    }
}

/// Tree that represents a continue statement.
///
///     > let q = #quote {
///     >   while true {
///     >     continue
///     >   }
///     > }
///     > print(q.structure)
///     Closure(
///       [],
///       [While(
///         nil,
///         [BooleanLiteral(
///           true,
///           TypeName("Bool", "s:Sb"))],
///         [Continue(
///            nil)])],
///       FunctionType(
///         [],
///         [],
///         TupleType(
///           [])))
public class Continue: Statement {
    public let label: String?

    public init(_ label: String?) {
        self.label = label
    }
}

/// Tree that represents a defer statement.
///
///     > let q = #quote {
///     >   defer {}
///     >   return
///     > }
///     > print(q.structure)
///     Closure(
///       [],
///       [Defer(
///         []),
///       Return(
///         Tuple(
///           [],
///           [],
///           TupleType(
///             [])))],
///       FunctionType(
///         [],
///         [],
///         TupleType(
///           [])))
public class Defer: Statement {
    public let body: [Statement]

    public init(_ body: [Statement]) {
        self.body = body
    }
}

/// Tree that represents a do statement.
///
///     > let q = #quote {
///     >   do {}
///     > }
///     > print(q.structure)
///     Closure(
///       [],
///       [Do(
///         [])],
///       FunctionType(
///         [],
///         [],
///         TupleType(
///           [])))
public class Do: Statement {
    public let label: String?
    public let body: [Statement]

    public init(_ label: String?, _ body: [Statement]) {
        self.label = label
        self.body = body
    }
}

/// Tree that represents a for-in loop.
///
///     > let range = 1...10
///     > let q = #quote {
///     >   for i in range {}
///     > }
///     > print(q.structure)
///     Closure(
///       [],
///       [For(
///         nil,
///         Name(
///           "i",
///           "s:4mainyycfU_1iL_Sivp",
///           TypeName("Int", "s:Si")),
///         Name(
///           "range",
///           "s:4main5rangeSNySiGvp",
///           SpecializedType(
///             TypeName("ClosedRange", "s:SN"),
///             [TypeName("Int", "s:Si")])),
///         [])],
///       FunctionType(
///         [],
///         [],
///         TupleType(
///           [])))
public class For: Statement {
    public let label: String?
    public let name: Name
    public let expression: Expression
    public let body: [Statement]

    public init(_ label: String?, _ name: Name, _ expression: Expression, _ body: [Statement]) {
        self.label = label
        self.name = name
        self.expression = expression
        self.body = body
    }
}

/// Tree that represents a guard statement.
///
///     > let q = #quote {
///     >   guard true else {}
///     > }
///     > print(q.structure)
///     Closure(
///       [],
///       [Guard(
///         [BooleanLiteral(
///           true,
///           TypeName("Bool", "s:Sb"))],
///         [])],
///       FunctionType(
///         [],
///         [],
///         TupleType(
///           [])))
public class Guard: Statement {
    public let condition: [Condition]
    public let body: [Statement]

    public init(_ condition: [Condition], _ body: [Statement]) {
        self.condition = condition
        self.body = body
    }
}

/// Tree that represents an if statement.
///
///     > let q = #quote {
///     >   if true {} else if false {} else {}
///     > }
///     > print(q.structure)
///     Closure(
///       [],
///       [If(
///         nil,
///         [BooleanLiteral(
///           true,
///           TypeName("Bool", "s:Sb"))],
///         [],
///         [If(
///           nil,
///           [BooleanLiteral(
///             false,
///             TypeName("Bool", "s:Sb"))],
///           [],
///           [])])],
///       FunctionType(
///         [],
///         [],
///         TupleType(
///           [])))
public class If: Statement {
    public let label: String?
    public let condition: [Condition]
    public let thenBranch: [Statement]
    public let elseBranch: [Statement]

    public init(
        _ label: String?, _ condition: [Condition], _ thenBranch: [Statement],
        _ elseBranch: [Statement]
    ) {
        self.label = label
        self.condition = condition
        self.thenBranch = thenBranch
        self.elseBranch = elseBranch
    }
}

/// Tree that represents a repeat-while loop.
///
///     > let q = #quote {
///     >   repeat {} while true
///     > }
///     > print(q.structure)
///     Closure(
///       [],
///       [Repeat(
///         nil,
///         [],
///         BooleanLiteral(
///           true,
///           TypeName("Bool", "s:Sb")))],
///       FunctionType(
///         [],
///         [],
///         TupleType(
///           [])))
public class Repeat: Statement {
    public let label: String?
    public let body: [Statement]
    public let condition: Expression

    public init(_ label: String?, _ body: [Statement], _ condition: Expression) {
        self.label = label
        self.body = body
        self.condition = condition
    }
}

/// Tree that represents a return statement.
///
///     > let q = #quote { () in return }
///     > print(q.structure)
///     Closure(
///       [],
///       [Return(
///         Tuple(
///           [],
///           [],
///           TupleType(
///             [])))],
///       FunctionType(
///         [],
///         [],
///         TupleType(
///           [])))
public class Return: Statement {
    public let expression: Expression

    public init(_ expression: Expression) {
        self.expression = expression
    }
}

/// Tree that represents a throw statement.
///
///     > class X: Error {}
///     > let q = #quote {
///     >   throw X()
///     > }
///     > print(q.structure)
///     Closure(
///       [],
///       [Throw(
///         Conversion(
///           Call(
///             Name(
///               "E",
///               "s:4main1ECXCycfc",
///               FunctionType(
///                 [],
///                 [],
///                 TypeName("X", "s:4main1XC"))),
///             [],
///             [],
///             TypeName("X", "s:4main1XC")),
///           TypeName("Error", "s:s5ErrorP")))],
///       FunctionType(
///         [],
///         [],
///         TupleType(
///           [])))
public class Throw: Statement {
    public let expression: Expression

    public init(_ expression: Expression) {
        self.expression = expression
    }
}

/// Tree that represents a while loop.
///
///     > let q = #quote {
///     >   while true {}
///     > }
///     > print(q.structure)
///     Closure(
///       [],
///       [While(
///         nil,
///         [BooleanLiteral(
///           true,
///           TypeName("Bool", "s:Sb"))],
///         [])],
///       FunctionType(
///         [],
///         [],
///         TupleType(
///           [])))
public class While: Statement {
    public let label: String?
    public let condition: [Condition]
    public let body: [Statement]

    public init(_ label: String?, _ condition: [Condition], _ body: [Statement]) {
        self.label = label
        self.condition = condition
        self.body = body
    }
}

// MARK: Expressions

/// Tree that represents a Swift expression.
/// Always has an associated type computed for this expression by the typechecker.
public protocol Expression: Statement, Condition {
    var type: Type { get }
}

/// Tree that represents an array literal [...].
///
///     > let q = #quote([40, 2])
///     > print(q.structure)
///     ArrayLiteral(
///       [IntegerLiteral(
///         40,
///         TypeName("Int", "s:Si")),
///       IntegerLiteral(
///         2,
///         TypeName("Int", "s:Si"))],
///       ArrayType(
///         TypeName("Int", "s:Si")))
public class ArrayLiteral: Expression {
    public let expressions: [Expression]
    public let type: Type

    public init(_ expressions: [Expression], _ type: Type) {
        self.expressions = expressions
        self.type = type
    }
}

/// Tree that represents an as expression.
///
///     > let q = #quote(42 as Int)
///     > print(q.structure)
///     As(
///       IntegerLiteral(
///         42,
///         TypeName("Int", "s:Si")))
public class As: Expression {
    public let expression: Expression
    public let type: Type

    public init(_ expression: Expression, _ type: Type) {
        self.expression = expression
        self.type = type
    }
}

/// Tree that represents an assignment expression.
///
///     > var x = 0
///     > let q = #quote(x = 42)
///     > print(q.structure)
///     Assign(
///       Name(
///         "x",
///         "s:4main1xSivp",
///          LValueType(
///            TypeName("Int", "s:Si"))),
///       IntegerLiteral(
///         42,
///         TypeName("Int", "s:Si")),
///       TupleType(
///         []))
public class Assign: Expression {
    public let lhs: Expression
    public let rhs: Expression
    public let type: Type

    public init(_ lhs: Expression, _ rhs: Expression, _ type: Type) {
        self.lhs = lhs
        self.rhs = rhs
        self.type = type
    }
}

/// Tree that represents a binary operator expression.
///
///     > let q = #quote(40 + 2)
///     > print(q.structure)
///     Binary(
///       IntegerLiteral(
///         40,
///         TypeName("Int", "s:Si")),
///       Name(
///         "+",
///         "s:Si1poiyS2i_SitFZ",
///         FunctionType(
///           [],
///           [TypeName("Int", "s:Si"),
///           TypeName("Int", "s:Si")],
///           TypeName("Int", "s:Si"))),
///       IntegerLiteral(
///         2,
///         TypeName("Int", "s:Si")),
///       TypeName("Int", "s:Si"))
public class Binary: Expression {
    public let lhs: Expression
    public let name: Name
    public let rhs: Expression
    public let type: Type

    public init(_ lhs: Expression, _ name: Name, _ rhs: Expression, _ type: Type) {
        self.lhs = lhs
        self.name = name
        self.rhs = rhs
        self.type = type
    }
}

/// Tree that represents a boolean literal.
///
///     > let q = #quote(true)
///     > print(q.structure)
///     BooleanLiteral(
///       true,
///       TypeName("Bool", "s:Sb"))
public class BooleanLiteral: Expression {
    public let value: Bool
    public let type: Type

    public init(_ value: Bool, _ type: Type) {
        self.value = value
        self.type = type
    }
}

/// Tree that represents a call expression.
/// This can include a function call, an init call, etc.
/// It is also a known issue that symbols of default arguments are empty (#27).
///
///     > let q = #quote(print(42))
///     > print(q.structure)
///     Call(
///       Name(
///         "print",
///         "s:s5print_9separator10terminatoryypd_S2StF",
///         FunctionType(
///           [],
///           [AndType(
///             []),
///           TypeName("String", "s:SS"),
///           TypeName("String", "s:SS")],
///           TupleType(
///             []))),
///       [nil],
///       [Varargs(
///         [IntegerLiteral(
///           42,
///           TypeName("Int", "s:Si"))],
///         ArrayType(
///           AndType(
///             []))),
///       Default(
///         "",
///         TypeName("String", "s:SS")),
///       Default(
///         "",
///         TypeName("String", "s:SS"))],
///       TupleType(
///         []))
public class Call: Expression {
    public let expression: Expression
    public let labels: [String?]
    public let arguments: [Expression]
    public let type: Type

    public init(
        _ expression: Expression,
        _ labels: [String?],
        _ arguments: [Expression],
        _ type: Type
    ) {
        self.expression = expression
        self.labels = labels
        self.arguments = arguments
        self.type = type
    }
}

/// Tree that represents a closure expression.
/// Note that the result type is not stored as a field but computed from the type of the expression.
///
///     > let q = #quote { (x: Int) in x }
///     > print(q.structure)
///     Closure(
///       [Parameter(
///         nil,
///         Name(
///           "x",
///           "s:4mainS2icfU_1xL_Sivp",
///           TypeName("Int", "s:Si")))],
///       [Return(
///         Name(
///           "x",
///           "s:4mainS2icfU_1xL_Sivp",
///           TypeName("Int", "s:Si")))],
///       FunctionType(
///         [],
///         [TypeName("Int", "s:Si")],
///         TypeName("Int", "s:Si")))
///
///     > func f(_ fn: @autoclosure () -> Int) {}
///     > let q = #quote(f(42))
///     > print(q.structure)
///     Call(
///       Name(
///         "f",
///         "s:4main1fyySiyXKF",
///         FunctionType(
///           [],
///           [FunctionType(
///             [],
///             [],
///             TypeName("Int", "s:Si"))],
///           TupleType(
///             []))),
///       [nil],
///       [Closure(
///         [],
///         [Return(
///           IntegerLiteral(
///             42,
///             TypeName("Int", "s:Si")))],
///         FunctionType(
///           [],
///           [],
///           TypeName("Int", "s:Si")))],
///       TupleType(
///         []))
public class Closure: Expression {
    public let parameters: [Parameter]

    public var result: Type {
        switch type {
        case let type as FunctionType:
            return type.result
        default:
            return UnknownTree()
        }
    }

    public let body: [Statement]
    public let type: Type

    public init(
        _ parameters: [Parameter],
        _ body: [Statement],
        _ type: Type
    ) {
        self.parameters = parameters
        self.body = body
        self.type = type
    }
}

/// Tree that represents one of the variety of implicit conversions applied by the Swift compiler.
///
/// For the comprehensive list, see ExprNodes.def in the sources of the compiler:
/// https://github.com/apple/swift/blob/master/include/swift/AST/ExprNodes.def#L146-L174
///
/// See `LValueType` for an example.
public class Conversion: Expression {
    public let expression: Expression
    public let type: Type

    public init(_ expression: Expression, _ type: Type) {
        self.expression = expression
        self.type = type
    }
}

/// Tree that represents a synthetic argument inserted into a call with a default parameter.
/// See `Call` for an example.
public class Default: Expression {
    public let symbol: String
    public let type: Type

    public init(_ symbol: String, _ type: Type) {
        self.symbol = symbol
        self.type = type
    }
}

/// Tree that represents a dictionary literal [...: ..., ...].
///
///     > let q = #quote([40: 40, 2: 2])
///     > print(q.structure)
///     DictionaryLiteral(
///       [IntegerLiteral(
///         40,
///         TypeName("Int", "s:Si")),
///       IntegerLiteral(
///         40,
///         TypeName("Int", "s:Si")),
///       IntegerLiteral(
///         2,
///         TypeName("Int", "s:Si")),
///       IntegerLiteral(
///         2,
///         TypeName("Int", "s:Si"))],
///       DictionaryType(
///         TypeName("Int", "s:Si"),
///         TypeName("Int", "s:Si")))
public class DictionaryLiteral: Expression {
    public let expressions: [Expression]
    public let type: Type

    public init(_ expressions: [Expression], _ type: Type) {
        self.expressions = expressions
        self.type = type
    }
}

/// Tree that represents a floating-point literal.
///
///     > let q = #quote(42.0)
///     > print(q.structure)
///     FloatLiteral(
///       42.0,
///       TypeName("Double", "s:Sd"))
public class FloatLiteral: Expression {
    public let value: Float
    public let type: Type

    public init(_ value: Float, _ type: Type) {
        self.value = value
        self.type = type
    }
}

/// Tree that represents a ! expression.
///
///     > let x: Int? = 42
///     > let q = #quote(x!)
///     > print(q.structure)
///     Force(
///       Name(
///         "x",
///         "s:4main1xypvp",
///         AndType(
///           [])),
///       TypeName("Int", "s:Si"))
public class Force: Expression {
    public let expression: Expression
    public let type: Type

    public init(_ expression: Expression, _ type: Type) {
        self.expression = expression
        self.type = type
    }
}

/// Tree that represents an as! expression.
///
///     > let x: Any = 42
///     > let q = #quote(x as! Int)
///     > print(q.structure)
///     ForceAs(
///       Name(
///         "x",
///         "s:4main1xypvp",
///         AndType(
///           [])),
///       TypeName("Int", "s:Si"))
public class ForceAs: Expression {
    public let expression: Expression
    public let type: Type

    public init(_ expression: Expression, _ type: Type) {
        self.expression = expression
        self.type = type
    }
}

/// Tree that represents a try! expression.
///
///     > let q = #quote(try! 42)
///     > print(q.structure)
///     ForceTry(
///       IntegerLiteral(
///         42,
///         TypeName("Int", "s:Si")))
public class ForceTry: Expression {
    public let expression: Expression
    public let type: Type

    public init(_ expression: Expression, _ type: Type) {
        self.expression = expression
        self.type = type
    }
}

/// Tree that represents an in-out expression.
///
///     > func foo(_ x: inout Int) {}
///     > var x = 42
///     > let q = #quote(foo(&x))
///     > print(q.structure)
///     Call(
///       Name(
///         "foo",
///         "s:4main3fooyySizF",
///         FunctionType(
///           [],
///           [InoutType(
///             TypeName("Int", "s:Si"))],
///           TupleType(
///             []))),
///       [nil],
///       [Inout(
///         Name(
///           "x",
///           "s:4main1xSivp",
///           LValueType(
///             TypeName("Int", "s:Si"))))],
///       TupleType(
///         []))
public class Inout: Expression {
    public let expression: Expression
    public let type: Type

    public init(_ expression: Expression, _ type: Type) {
        self.expression = expression
        self.type = type
    }
}

/// Tree that represents an integer literal.
///
///     > let q = #quote(42)
///     > print(q.structure)
///     IntegerLiteral(
///       42,
///       TypeName("Int", "s:Si"))
public class IntegerLiteral: Expression {
    public let value: Int
    public let type: Type

    public init(_ value: Int, _ type: Type) {
        self.value = value
        self.type = type
    }
}

/// Tree that represents an as expression.
///
///     > let x: Any = 42
///     > let q = #quote(x is Int)
///     > print(q.structure)
///     Is(
///       Name(
///         "x",
///         "s:4main1xypvp",
///         AndType(
///           [])),
///       TypeName("Int", "s:Si"),
///       TypeName("Bool", "s:Sb"))
public class Is: Expression {
    public let expression: Expression
    public let targetType: Type
    public let type: Type

    public init(_ expression: Expression, _ targetType: Type, _ type: Type) {
        self.expression = expression
        self.targetType = targetType
        self.type = type
    }
}

/// Tree that represents a magic literal, i.e. #file, #line, #column, #function or #dsohandle.
///
///     > let q = #quote(#file)
///     > print(q.structure)
///     MagicLiteral(
///       "file",
///       TypeName("String", "s:SS"))
public class MagicLiteral: Expression {
    public let kind: String
    public let type: Type

    public init(_ kind: String, _ type: Type) {
        self.kind = kind
        self.type = type
    }
}

/// Tree that represents member selection.
/// This can include a field selection, a method selection, etc.
/// However, subscript selections are their own thing because they don't have names.
///
///     > let x = [1, 2, 3]
///     > let q = #quote(x.count)
///     > print(q.structure)
///     Member(
///       Name(
///         "x",
///         "s:4main1xSaySiGvp",
///         ArrayType(
///           TypeName("Int", "s:Si"))),
///       "count",
///       "s:Sa5countSivp",
///       TypeName("Int", "s:Si"))
///
/// Static members are represented as selections from type exprs in the Swift compiler,
/// but in our trees they are represented as names to avoid getting into the rabbit hole of
/// exposing type exprs, metatypes, etc for this supposedly simple use case.
///
///     > class Context { static let local = Context() }
///     > let q = #quote(Context.local)
///     > print(q.structure)
///     Name(
///       "local",
///       "s:4main7ContextC5localACvpZ",
///       TypeName("Context", "s:4main7ContextC"))
///
///     > enum E { case a }
///     > let q = #quote(E.a)
///     > print(q.structure)
///     Name(
///       "a",
///       "s:4main1EO1ayA2CmF",
///       TypeName("E", "s:4main1EO"))
///
/// When a selection doesn't actually need the actual value of expression to be evaluated,
/// we also represent the selection as a name.
///
///     func g() {}
///     let q = #quote(main.g())
///     print(q.structure)
///     Call(
///       Name(
///         "f",
///         "s:4main1gyyF",
///         FunctionType(
///           [],
///           [],
///           TupleType(
///             []))),
///       [],
///       [],
///       TupleType(
///         []))
///
/// Selection from a tuple is modelled as `TupleElement`.
public class Member: Expression {
    public let expression: Expression
    public let value: String
    public let symbol: String
    public let type: Type

    public init(_ expression: Expression, _ value: String, _ symbol: String, _ type: Type) {
        self.expression = expression
        self.value = value
        self.symbol = symbol
        self.type = type
    }
}

/// Tree that represents a #quote(...) expression.
///
///     > let q = #quote(#quote(42))
///     > print(q.structure)
///     Meta(
///       IntegerLiteral(
///         42,
///         TypeName("Int", "s:Si")),
///       SpecializedType(
///         TypeName("Quote", "s:5QuoteAAC"),
///         [TypeName("Int", "s:Si")]))
public class Meta: Expression {
    public let expression: Expression
    public let type: Type

    public init(_ expression: Expression, _ type: Type) {
        self.expression = expression
        self.type = type
    }
}

/// Tree that represents a reference to a value, func, etc.
///
///     > let x = 42
///     > let q = #quote(x)
///     > print(q.structure)
///     Name(
///       "x",
///       "s:4main1xSivp",
///       TypeName("Int", "s:Si"))
public class Name: Expression {
    public let value: String
    public let symbol: String
    public let type: Type

    public init(_ value: String, _ symbol: String, _ type: Type) {
        self.value = value
        self.symbol = symbol
        self.type = type
    }
}

/// Tree that represents a nil literal.
///
///     > let q = #quote(nil as Int?)
///     > print(q.structure)
///     As(
///       NilLiteral(
///         OptionalType(
///           TypeName("Int", "s:Si"))),
///       OptionalType(
///         TypeName("Int", "s:Si")))
public class NilLiteral: Expression {
    public let type: Type

    public init(_ type: Type) {
        self.type = type
    }
}

/// Tree that represents an as? expression.
///
///     > let x: Any = 42
///     > let q = #quote(x as? Int)
///     > print(q.structure)
///     OptionalAs(
///       Name(
///         "x",
///         "s:4main1xypvp",
///         AndType(
///           [])),
///       TypeName("Int", "s:Si"),
///       OptionalType(
///         TypeName("Int", "s:Si")))
public class OptionalAs: Expression {
    public let expression: Expression
    public let targetType: Type
    public let type: Type

    public init(_ expression: Expression, _ targetType: Type, _ type: Type) {
        self.expression = expression
        self.targetType = targetType
        self.type = type
    }
}

/// Tree that represents a try? expression.
///
///     > let q = #quote(try? 42)
///     > print(q.structure)
///     OptionalTry(
///       Conversion(
///         IntegerLiteral(
///           42,
///           TypeName("Int", "s:Si")),
///         OptionalType(
///           TypeName("Int", "s:Si"))))
public class OptionalTry: Expression {
    public let expression: Expression
    public let type: Type

    public init(_ expression: Expression, _ type: Type) {
        self.expression = expression
        self.type = type
    }
}

/// Tree that represents a postfix operator expression.
public class Postfix: Expression {
    public let expression: Expression
    public let name: Name
    public let type: Type

    public init(_ expression: Expression, _ name: Name, _ type: Type) {
        self.expression = expression
        self.name = name
        self.type = type
    }
}

/// Tree that represents a postfix self expression expr.self or T.self.
///
///     > let q = #quote(42.self)
///     > print(q.structure)
///     PostfixSelf(
///       IntegerLiteral(
///         42,
///         TypeName("Int", "s:Si")),
///       TypeName("Int", "s:Si"))
///
///     > let q = #quote(Int.self)
///     > print(q.structure)
///     PostfixSelf(
///       TypeName("Int", "s:Si"),
///       MetaType(
///         TypeName("Int", "s:Si")))
public class PostfixSelf: Expression {
    public let tree: Tree
    public let type: Type

    public init(_ tree: Tree, _ type: Type) {
        self.tree = tree
        self.type = type
    }
}

/// Tree that represents a prefix operator expression.
///
///     > let q = #quote(+42)
///     > print(q.structure)
///     Prefix(
///       Name(
///         "+",
///         "s:s18AdditiveArithmeticPsE1popyxxFZ",
///         FunctionType(
///           [],
///           [TypeName("Int", "s:Si")],
///           TypeName("Int", "s:Si"))),
///       IntegerLiteral(
///         42,
///         TypeName("Int", "s:Si")),
///       TypeName("Int", "s:Si"))
public class Prefix: Expression {
    public let name: Name
    public let expression: Expression
    public let type: Type

    public init(_ name: Name, _ expression: Expression, _ type: Type) {
        self.name = name
        self.expression = expression
        self.type = type
    }
}

/// Tree that provides an incomplete representation of a string interpolation expression.
/// TODO(TF-723): Finish the implementation.
///
///     > let x = 42
///     > let q = #quote("x = \(x)")
///     > print(q.structure)
///     StringInterpolation(
///       TypeName("String", "s:SS"))
public class StringInterpolation: Expression {
    public let type: Type

    public init(_ type: Type) {
        self.type = type
    }
}

/// Tree that represents a string literal.
///
///     > let q = #quote("42")
///     > print(q.structure)
///     StringLiteral(
///       "42",
///       TypeName("Int", "s:SS"))
public class StringLiteral: Expression {
    public let value: String
    public let type: Type

    public init(_ value: String, _ type: Type) {
        self.value = value
        self.type = type
    }
}

/// Tree that represents a subscript expression.
///
///     > let x = [1, 2, 3]
///     > let q = #quote(x[0])
///     > print(q.structure)
///     Subscript(
///       Name(
///         "x",
///         "s:4main1xSaySiGvp",
///         ArrayType(
///           TypeName("Int", "s:Si"))),
///       "s:SayxSicip",
///       [nil],
///       [IntegerLiteral(
///         0,
///         TypeName("Int", "s:Si"))],
///       TypeName("Int", "s:Si"))
public class Subscript: Expression {
    public let expression: Expression
    public let symbol: String
    public let labels: [String?]
    public let arguments: [Expression]
    public let type: Type

    public init(
        _ expression: Expression,
        _ symbol: String,
        _ labels: [String?],
        _ arguments: [Expression],
        _ type: Type
    ) {
        self.expression = expression
        self.symbol = symbol
        self.labels = labels
        self.arguments = arguments
        self.type = type
    }
}

/// Tree that represents a super expression.
///
///     > class C {
///     >   func p() {}
///     > }
///     > class D: C {
///     >   func q() {
///     >     let q = #quote(super.p())
///     >     print(q.structure)
///     >   }
///     > }
///     > D().q()
///     Call(
///       Member(
///         Super(
///           TypeName("C", "s:4main1CC")),
///         "p",
///         "s:4main1CC1pyyF",
///         FunctionType(
///           [],
///           [],
///           TupleType(
///             []))),
///       [],
///       [],
///       TupleType(
///         []))
public class Super: Expression {
    public let type: Type

    public init(_ type: Type) {
        self.type = type
    }
}

/// Tree that represents a ternary operator expression.
///
///     > let q = #quote(true ? 40 : 2)
///     > print(q.structure)
///     Ternary(
///       BooleanLiteral(
///         true,
///         TypeName("Bool", "s:Sb")),
///       IntegerLiteral(
///         40,
///         TypeName("Int", "s:Si")),
///       IntegerLiteral(
///         2,
///         TypeName("Int", "s:Si")),
///       TypeName("Int", "s:Si"))
public class Ternary: Expression {
    public let condition: Expression
    public let thenBranch: Expression
    public let elseBranch: Expression
    public let type: Type

    public init(
        _ condition: Expression,
        _ thenBranch: Expression,
        _ elseBranch: Expression,
        _ type: Type
    ) {
        self.condition = condition
        self.thenBranch = thenBranch
        self.elseBranch = elseBranch
        self.type = type
    }
}

/// Tree that represents a try expression.
///
///     > let q = #quote(try 42)
///     > print(q.structure)
///     Try(
///       IntegerLiteral(
///         42,
///         TypeName("Int", "s:Si")))
public class Try: Expression {
    public let expression: Expression
    public let type: Type

    public init(_ expression: Expression, _ type: Type) {
        self.expression = expression
        self.type = type
    }
}

/// Tree that represents a tuple expression.
///
///     > let q = #quote((1, "2", 3))
///     > print(q.structure)
///     Tuple(
///       [],
///       [IntegerLiteral(
///         1,
///         TypeName("Int", "s:Si")),
///       StringLiteral(
///         "2",
///         TypeName("String", "s:SS")),
///       IntegerLiteral(
///         3,
///         TypeName("Int", "s:Si"))],
///       TupleType(
///         [TypeName("Int", "s:Si"),
///         TypeName("String", "s:SS"),
///         TypeName("Int", "s:Si")]))
public class Tuple: Expression {
    public let labels: [String?]
    public let arguments: [Expression]
    public let type: Type

    public init(
        _ labels: [String?],
        _ arguments: [Expression],
        _ type: Type
    ) {
        self.labels = labels
        self.arguments = arguments
        self.type = type
    }
}

/// Tree that represents selection of a tuple element.
/// It is a known issue that sometimes the type of the associate Tuple is unknown (#1).
///
///     > let q = #quote((1, 2).1)
///     > print(q.structure)
///     TupleElement(
///       Tuple(
///         [],
///         [IntegerLiteral(
///           1,
///           TypeName("Int", "s:Si")),
///         IntegerLiteral(
///           2,
///           TypeName("Int", "s:Si"))],
///         UnknownTree()),
///       1,
///       TypeName("Int", "s:Si"))
public class TupleElement: Expression {
    public let expression: Expression
    public let field: Int
    public let type: Type

    public init(_ expression: Expression, _ field: Int, _ type: Type) {
        self.expression = expression
        self.field = field
        self.type = type
    }
}

/// Tree that represents the #unquote(...) expression.
/// Note how it contains both the AST representation of the unquoted expression and the actual value
/// of that expression. The actual value is wrapped in a no-parameter closure to allow for mutually
/// recursive quotes.
///
///     > let x = #quote(40)
///     > let q = #quote(#unquote(x) + 2)
///     > print(q.structure)
///     Binary(
///       Unquote(
///         Name(
///           "x",
///           "s:4main1x5QuoteACCySiGvp",
///           SpecializedType(
///             TypeName("Quote", "s:5QuoteAAC"),
///             [TypeName("Int", "s:Si")])),
///         40,
///         TypeName("Int", "s:Si")),
///       Name(
///         "+",
///         "s:Si1poiyS2i_SitFZ",
///         FunctionType(
///           [],
///           [TypeName("Int", "s:Si"),
///           TypeName("Int", "s:Si")],
///           TypeName("Int", "s:Si"))),
///       IntegerLiteral(
///         2,
///         TypeName("Int", "s:Si")),
///       TypeName("Int", "s:Si"))
public class Unquote: Expression {
    public let expression: Expression
    public let value: () -> Tree
    public let type: Type

    public init(
        _ expression: Expression,
        _ value: @autoclosure @escaping () -> Tree,
        _ type: Type
    ) {
        self.expression = expression
        self.value = value
        self.type = type
    }
}

/// Tree that represents a synthetic argument inserted into a call with a vararg parameter.
/// See `Call` for an example.
public class Varargs: Expression {
    public let expressions: [Expression]
    public let type: Type

    public init(_ expressions: [Expression], _ type: Type) {
        self.expressions = expressions
        self.type = type
    }
}

/// Tree that represents a wildcard, i.e. `_`.
///
///     > let q = #quote(_ = 42)
///     > print(q.structure)
///     Assign(
///       Wildcard(),
///       IntegerLiteral(
///         42,
///         TypeName("Int", "s:Si")),
///       TupleType(
///         []))
public class Wildcard: Expression {
    public var type: Type {
        return UnknownTree()
    }

    public init() {
    }
}

// MARK: Declarations

/// Tree that represents a Swift declaration.
public protocol Declaration: Statement {
}

/// Tree that represents a `func` declaration.
/// Note that the result type is not stored as a field but computed from the type of name.
/// It is a known issue that local functions cannot be quoted (#5).
///
///     > @quoted
///     > func foo(_ x: Int) -> Int {
///     >   return x
///     > }
///     > print(#quote(foo).structure)
///     Unquote(
///       Name(
///         "foo",
///         "s:4main3fooyS2iF",
///         FunctionType(
///           [],
///           [TypeName("Int", "s:Si")],
///           TypeName("Int", "s:Si"))),
///       func foo(_ x: Int) -> Int in
///       return x
///     }  ,
///       SpecializedType(
///         TypeName("FunctionQuote1", "s:5Quote14FunctionQuote1C"),
///         [TypeName("Int", "s:Si"),
///         TypeName("Int", "s:Si")]))
public class Function: Declaration {
    public let name: Name
    public let parameters: [Parameter]

    public var result: Type {
        switch name.type {
        case let type as FunctionType:
            return type.result
        default:
            return UnknownTree()
        }
    }

    public let body: [Statement]

    public init(
        _ name: Name,
        _ parameters: [Parameter],
        _ body: [Statement]
    ) {
        self.name = name
        self.parameters = parameters
        self.body = body
    }
}

/// Tree that represents a `let` declaration.
/// Note that the result type is not stored as a field but computed from the type of name.
///
///     > let q = #quote { let x = 42 };
///     > print(q.structure);
///     Closure(
///       [],
///       [Let(
///         Name(
///           "x",
///           "s:4mainyycfU_1xL_Sivp",
///           TypeName("Int", "s:Si")),
///         IntegerLiteral(
///           42,
///           TypeName("Int", "s:Si")))],
///       FunctionType(
///         [],
///         [],
///         TupleType(
///           [])))
public class Let: Declaration {
    public let name: Name
    public var type: Type { return name.type }
    public let rhs: Expression

    public init(_ name: Name, _ rhs: Expression) {
        self.name = name
        self.rhs = rhs
    }
}

/// Tree that represents a parameter declaration.
/// See `Closure` for an example.
public class Parameter: Tree {
    public let label: String?
    public let name: Name
    public var type: Type { return name.type }

    public init(_ label: String?, _ name: Name) {
        self.label = label
        self.name = name
    }
}

/// Tree that represents a `var` declaration.
/// Note that the result type is not stored as a field but computed from the type of name.
///
///     > let q = #quote { var x = 42 };
///     > print(q.structure);
///     Closure(
///       [],
///       [Var(
///         Name(
///           "x",
///           "s:4mainyycfU_1xL_Sivp",
///           TypeName("Int", "s:Si")),
///         IntegerLiteral(
///           42,
///           TypeName("Int", "s:Si")))],
///       FunctionType(
///         []
///         [],
///         TupleType(
///           [])))
public class Var: Declaration {
    public let name: Name
    public var type: Type { return name.type }
    public let rhs: Expression

    public init(_ name: Name, _ rhs: Expression) {
        self.name = name
        self.rhs = rhs
    }
}
