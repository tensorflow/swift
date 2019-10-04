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
    /// Returns Swift-like syntax of the tree.
    /// The printouts may contain occurrences of <?> which stand for `UnknownTree`
    /// nodes which represent unsupported language constructs.
    public var description: String {
        let p = DescriptionPrinter()
        p.print(self)
        return p.description
    }
}

extension Quote {
    /// Returns Swift-like syntax of the underlying tree.
    public var description: String {
        return expression.description
    }
}

class DescriptionPrinter: Printer {
    func print(_ tree: Tree) {
        switch tree {
        case _ as Differentiable:
            print("@differentiable")
        case let x as AndType:
            print(x.types, " & ") { print($0) }
        case let x as ArrayType:
            print("[")
            print(x.type)
            print("]")
        case let x as DictionaryType:
            print("[")
            print(x.key)
            print(": ")
            print(x.value)
            print("]")
        case let x as FunctionType:
            print(whenEmpty: false, "", x.attributes, " ", " ") { print($0) }
            print("(", x.parameters, ", ", ")") { print($0) }
            print(" -> ")
            print(x.result)
        case let x as InoutType:
            print("inout ")
            print(x.type)
        case let x as LValueType:
            print(x.type)
        case let x as MetaType:
            // NOTE: We don't have enough context to decide whether we should say .Type or .Protocol here.
            // However, it's just a prettyprinter - we don't have to emit 100% valid Swift code.
            print(x.type)
            print(".Type")
        case let x as OptionalType:
            print(x.type)
            print("?")
        case let x as SpecializedType:
            print(x.type)
            print("[", x.arguments, ", ", "]") { print($0) }
        case let x as TupleType:
            print("(", x.types, ", ", ")") { print($0) }
        case let x as TypeName:
            print(x.value)
        case let x as Break:
            print("break")
            print(" ", x.label) { print($0) }
        case let x as Continue:
            print("continue")
            print(" ", x.label) { print($0) }
        case let x as Defer:
            print("defer")
            printBody(" {\n", x.body, "}")
        case let x as Do:
            print(x.label, ": ") { print($0) }
            print("do")
            printBody(" {\n", x.body, "}")
        case let x as For:
            print(x.label, ": ") { print($0) }
            print("for ")
            print(x.name)
            print(" in ")
            print(x.expression)
            printBody(" {\n", x.body, "}")
        case let x as Guard:
            print("guard ")
            print(x.condition, ", ") { print($0) }
            printBody(" else {\n", x.body, "}")
        case let x as If:
            print(x.label, ": ") { print($0) }
            print("if ")
            print(x.condition, ", ") { print($0) }
            printBody(" {\n", x.thenBranch, "}")
            guard x.elseBranch.count > 0 else { return }
            printBody(" else {\n", x.elseBranch, "}")
        case let x as Repeat:
            print(x.label, ": ") { print($0) }
            print("repeat")
            printBody(" {\n", x.body, "}")
            print(" while ")
            print(x.condition)
        case let x as Return:
            print("return ")
            print(x.expression)
        case let x as Throw:
            print("throw ")
            print(x.expression)
        case let x as While:
            print(x.label, ": ") { print($0) }
            print("while ")
            print(x.condition, ", ") { print($0) }
            printBody(" {\n", x.body, "}")
        case let x as ArrayLiteral:
            print("[", x.expressions, ", ", "]") { print($0) }
        case let x as As:
            print("(")
            print(x.expression)
            print(" as ")
            print(x.type)
            print(")")
        case let x as Assign:
            print(x.lhs)
            print(" = ")
            print(x.rhs)
        case let x as Binary:
            print("(")
            print(x.lhs)
            print(" ")
            print(x.name)
            print(" ")
            print(x.rhs)
            print(")")
        case let x as BooleanLiteral:
            print(x.value)
        case let x as Call:
            print(x.expression)
            print("(")
            printArguments(x.labels, x.arguments)
            print(")")
        case let x as Closure:
            print("{ ")
            print("(", x.parameters, ", ", ")") {
                print($0.name)
                print(": ")
                print($0.type)
            }
            print(" -> ")
            print(x.result)
            printBody(" in\n", x.body, "}")
        case let x as Conversion:
            print(x.expression)
        case let x as DictionaryLiteral:
            print("[")
            var sep = ""
            for expr in x.expressions {
                if sep.count != 0 {
                    print(sep)
                }
                sep = sep == ": " ? ", " : ": "
                print(expr)
            }
            print("]")
        case let x as FloatLiteral:
            print(x.value)
        case let x as Force:
            print(x.expression)
            print("!")
        case let x as ForceAs:
            print("(")
            print(x.expression)
            print(" as! ")
            print(x.type)
            print(")")
        case let x as ForceTry:
            print("try! ")
            print(x.expression)
        case let x as Inout:
            print("&")
            print(x.expression)
        case let x as IntegerLiteral:
            print(x.value)
        case let x as Is:
            print("(")
            print(x.expression)
            print(" is ")
            print(x.targetType)
            print(")")
        case let x as MagicLiteral:
            print("#")
            print(x.kind)
        case let x as Member:
            print(x.expression)
            print(".")
            print(x.value)
        case let x as Meta:
            print("#quote(")
            print(x.expression)
            print(")")
        case let x as Name:
            print(x.value)
        case _ as NilLiteral:
            print("nil")
        case let x as OptionalAs:
            print("(")
            print(x.expression)
            print(" as? ")
            print(x.targetType)
            print(")")
        case let x as OptionalTry:
            print("try? ")
            print(x.expression)
        case let x as Postfix:
            print("(")
            print(x.expression)
            print(x.name)
            print(")")
        case let x as PostfixSelf:
            print(x.tree)
            print(".self")
        case let x as Prefix:
            print("(")
            print(x.name)
            print(x.expression)
            print(")")
        case _ as StringInterpolation:
            literal("...")
        case let x as StringLiteral:
            literal(x.value)
        case let x as Subscript:
            print(x.expression)
            print("[")
            printArguments(x.labels, x.arguments)
            print("]")
        case _ as Super:
            print("super")
        case let x as Ternary:
            print("(")
            print(x.condition)
            print(" ? ")
            print(x.thenBranch)
            print(" : ")
            print(x.elseBranch)
            print(")")
        case let x as Try:
            print("try ")
            print(x.expression)
        case let x as Tuple:
            print("(")
            printArguments(x.labels, x.arguments)
            print(")")
        case let x as TupleElement:
            print(x.expression)
            print(".")
            print(x.field)
        case let x as Unquote:
            print("#unquote(")
            print(x.expression)
            print(")")
        case _ as Wildcard:
            print("_")
        case let x as Function:
            print("func ")
            print(x.name)
            print("(", x.parameters, ", ", ")") { print($0) }
            print(" -> ")
            print(x.result)
            printBody(" in\n", x.body, "}")
        case let x as Let:
            print("let ")
            print(x.name)
            print(": ", x.type) { print($0) }
            print(" = ")
            print(x.rhs)
        case let x as Parameter:
            if let label = x.label {
                print(label)
                print(": ")
            } else {
                print("_ ")
            }
            print(x.name)
            print(": ")
            print(x.type)
        case let x as Var:
            print("var ")
            print(x.name)
            print(": ", x.type) { print($0) }
            print(" = ")
            print(x.rhs)
        default:
            print("<?>")
        }
    }

    private func printArguments(_ labels: [String?], _ arguments: [Expression]) {
        var needComma = false
        // TODO(TF-731): Figure out why this is necessary.
        var fixedLabels: [String?] = labels
        if labels.count == 0 {
            fixedLabels = Array(repeating: nil, count: arguments.count)
        }
        for (label, argument) in zip(fixedLabels, arguments) {
            if argument is Default {
                print("")
            } else {
                if (needComma) {
                    needComma = false
                    print(", ")
                }
                print(label, ": ") { print($0) }
                if let arguments = argument as? Varargs {
                    print(arguments.expressions, ", ") { print($0) }
                } else {
                    print(argument)
                }
                needComma = true
            }
        }
    }

    private func printBody(_ pre: String, _ body: [Statement], _ suffix: String) {
        print(pre)
        indent()
        print(whenEmpty: false, "", body, "\n", "\n") { print($0) }
        unindent()
        print(suffix)
    }
}
