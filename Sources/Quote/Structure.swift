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

extension Tree {
    /// Returns a string that can be copy/pasted into a Swift program or REPL
    /// and reconstruct the tree.
    public var structure: String {
        let p = StructurePrinter()
        p.print(self)
        return p.description
    }
}

extension Quote {
    /// Returns a string that can be copy/pasted into a Swift program or REPL
    /// and reconstruct the underlying tree.
    public var structure: String {
        return expression.structure
    }
}

class StructurePrinter: Printer {
    func print(_ tree: Tree) {
        switch tree {
        case _ as Differentiable:
            print("Differentiable()")
        case let x as AndType:
            object("AndType") {
                collection("types", x.types) { print($0) }
            }
        case let x as ArrayType:
            object("ArrayType") {
                scalar("type", x.type) { print($0) }
            }
        case let x as DictionaryType:
            object("DictionaryType") {
                scalar("key", x.key) { print($0) }
                scalar("value", x.value) { print($0) }
            }
        case let x as FunctionType:
            object("FunctionType") {
                collection("attributes", x.attributes) { print($0) }
                collection("parameters", x.parameters) { print($0) }
                scalar("result", x.result) { print($0) }
            }
        case let x as InoutType:
            object("InoutType") {
                scalar("type", x.type) { print($0) }
            }
        case let x as LValueType:
            object("LValueType") {
                scalar("type", x.type) { print($0) }
            }
        case let x as MetaType:
            object("MetaType") {
                scalar("type", x.type) { print($0) }
            }
        case let x as OptionalType:
            object("OptionalType") {
                scalar("type", x.type) { print($0) }
            }
        case let x as SpecializedType:
            object("SpecializedType") {
                scalar("type", x.type) { print($0) }
                collection("arguments", x.arguments) { print($0) }
            }
        case let x as TupleType:
            object("TupleType") {
                collection("types", x.types) { print($0) }
            }
        case let x as TypeName:
            print("TypeName(")
            literal(x.value)
            print(", ")
            literal(x.symbol)
            print(")")
        case let x as Break:
            object("Break") {
                scalar("label", x.label) { literal($0) }
            }
        case let x as Continue:
            object("Continue") {
                scalar("label", x.label) { literal($0) }
            }
        case let x as Defer:
            object("Defer") {
                collection("body", x.body) { print($0) }
            }
        case let x as Do:
            object("Do") {
                scalar("label", x.label) { literal($0) }
                collection("body", x.body) { print($0) }
            }
        case let x as For:
            object("For") {
                scalar("label", x.label) { literal($0) }
                scalar("name", x.name) { print($0) }
                scalar("expression", x.expression) { print($0) }
                collection("body", x.body) { print($0) }
            }
        case let x as Guard:
            object("Guard") {
                collection("condition", x.condition) { print($0) }
                collection("body", x.body) { print($0) }
            }
        case let x as If:
            object("If") {
                scalar("label", x.label) { literal($0) }
                collection("condition", x.condition) { print($0) }
                collection("thenBranch", x.thenBranch) { print($0) }
                collection("elseBranch", x.elseBranch) { print($0) }
            }
        case let x as Repeat:
            object("Repeat") {
                scalar("label", x.label) { literal($0) }
                collection("body", x.body) { print($0) }
                scalar("condition", x.condition) { print($0) }
            }
        case let x as Return:
            object("Return") {
                scalar("expression", x.expression) { print($0) }
            }
        case let x as Throw:
            object("Throw") {
                scalar("expression", x.expression) { print($0) }
            }
        case let x as While:
            object("While") {
                scalar("label", x.label) { literal($0) }
                collection("condition", x.condition) { print($0) }
                collection("body", x.body) { print($0) }
            }
        case let x as ArrayLiteral:
            object("ArrayLiteral") {
                collection("expressions", x.expressions) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as As:
            object("As") {
                scalar("expression", x.expression) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as Assign:
            object("Assign") {
                scalar("lhs", x.lhs) { print($0) }
                scalar("rhs", x.rhs) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as Binary:
            object("Binary") {
                scalar("lhs", x.lhs) { print($0) }
                scalar("name", x.name) { print($0) }
                scalar("rhs", x.rhs) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as BooleanLiteral:
            object("BooleanLiteral") {
                scalar("value", x.value) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as Call:
            object("Call") {
                scalar("expression", x.expression) { print($0) }
                collection("labels", x.labels) { literal($0) }
                collection("arguments", x.arguments) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as Default:
            object("Default") {
                scalar("symbol", x.symbol) { literal($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as DictionaryLiteral:
            object("DictionaryLiteral") {
                collection("expressions", x.expressions) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as Closure:
            object("Closure") {
                collection("parameters", x.parameters) { print($0) }
                collection("body", x.body) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as Conversion:
            object("Conversion") {
                scalar("expression", x.expression) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as FloatLiteral:
            object("FloatLiteral") {
                scalar("value", x.value) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as Force:
            object("Force") {
                scalar("expression", x.expression) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as ForceAs:
            object("ForceAs") {
                scalar("expression", x.expression) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as ForceTry:
            object("ForceTry") {
                scalar("expression", x.expression) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as Inout:
            object("InOut") {
                scalar("expression", x.expression) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as IntegerLiteral:
            object("IntegerLiteral") {
                scalar("value", x.value) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as Is:
            object("Is") {
                scalar("expression", x.expression) { print($0) }
                scalar("targetType", x.targetType) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as MagicLiteral:
            object("MagicLiteral") {
                scalar("kind", x.kind) { literal($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as Member:
            object("Member") {
                scalar("expression", x.expression) { print($0) }
                scalar("value", x.value) { literal($0) }
                scalar("symbol", x.symbol) { literal($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as Meta:
            object("Meta") {
                scalar("expression", x.expression) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as Name:
            object("Name") {
                scalar("value", x.value) { literal($0) }
                scalar("symbol", x.symbol) { literal($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as NilLiteral:
            object("NilLiteral") {
                scalar("type", x.type) { print($0) }
            }
        case let x as OptionalAs:
            object("OptionalAs") {
                scalar("expression", x.expression) { print($0) }
                scalar("targetType", x.targetType) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as OptionalTry:
            object("OptionalTry") {
                scalar("expression", x.expression) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as Postfix:
            object("Postfix") {
                scalar("expression", x.expression) { print($0) }
                scalar("name", x.name) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as PostfixSelf:
            object("PostfixSelf") {
                scalar("tree", x.tree) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as Prefix:
            object("Prefix") {
                scalar("name", x.name) { print($0) }
                scalar("expression", x.expression) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as StringInterpolation:
            object("StringInterpolation") {
                scalar("type", x.type) { print($0) }
            }
        case let x as StringLiteral:
            object("StringLiteral") {
                scalar("value", x.value) { literal($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as Subscript:
            object("Subscript") {
                scalar("expression", x.expression) { print($0) }
                scalar("symbol", x.symbol) { literal($0) }
                collection("labels", x.labels) { literal($0) }
                collection("arguments", x.arguments) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as Super:
            object("Super") {
                scalar("type", x.type) { print($0) }
            }
        case let x as Ternary:
            object("Ternary") {
                scalar("condition", x.condition) { print($0) }
                scalar("thenBranch", x.thenBranch) { print($0) }
                scalar("elseBranch", x.elseBranch) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as Try:
            object("Try") {
                scalar("expression", x.expression) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as Tuple:
            object("Tuple") {
                collection("labels", x.labels) { literal($0) }
                collection("arguments", x.arguments) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as TupleElement:
            object("TupleElement") {
                scalar("expression", x.expression) { print($0) }
                scalar("field", x.field) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case let x as Unquote:
            object("Unquote") {
                scalar("expression", x.expression) { print($0) }
                scalar("value", x.value) { print($0().description) }
                scalar("type", x.type) { print($0) }
            }
        case let x as Varargs:
            object("Varargs") {
                collection("expressions", x.expressions) { print($0) }
                scalar("type", x.type) { print($0) }
            }
        case _ as Wildcard:
            print("Wildcard()")
        case let x as Function:
            object("Function") {
                scalar("name", x.name) { print($0) }
                collection("parameters", x.parameters) { print($0) }
                collection("body", x.body) { print($0) }
            }
        case let x as Let:
            object("Let") {
                scalar("name", x.name) { print($0) }
                scalar("rhs", x.rhs) { print($0) }
            }
        case let x as Parameter:
            object("Parameter") {
                scalar("label", x.label) { literal($0) }
                scalar("name", x.name) { print($0) }
            }
        case let x as Var:
            object("Var") {
                scalar("name", x.name) { print($0) }
                scalar("rhs", x.rhs) { print($0) }
            }
        case _ as UnknownTree:
            print("UnknownTree()")
        default:
            print("<?>")
        }
    }

    private func object(_ name: String, _ fn: () -> Void) {
        print(name)
        print("(")
        indent()
        fn()
        unindent()
        print(")")
    }

    private func scalar<T>(_ name: String, _ value: T, _ fn: (T) -> Void) {
        let c = description.last!
        if c == "(" || c == "[" {
            print("\n")
            fn(value)
        } else {
            print(",\n")
            fn(value)
        }
    }

    private func collection<S: Sequence>(
        _ name: String,
        _ value: S,
        _ fn: (S.Element) -> Void
    ) {
        scalar(name, value) {
            print("[")
            var needSep = false
            for el in $0 {
                if needSep {
                    print(",\n")
                }
                needSep = true
                fn(el)
            }
            print("]")
        }
    }
}
