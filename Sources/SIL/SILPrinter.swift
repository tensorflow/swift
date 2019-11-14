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

class SILPrinter: Printer {
    func print(_ module: Module) {
        print(module.functions, "\n\n") { print($0) }
    }

    func print(_ function: Function) {
        print("sil ")
        print(function.linkage)
        print(whenEmpty: false, "", function.attributes, " ", " ") { print($0) }
        print("@")
        print(function.name)
        print(" : ")
        print(function.type)
        print(whenEmpty: false, " {\n", function.blocks, "\n", "}") { print($0) }
    }

    func print(_ block: Block) {
        print(block.identifier)
        print(whenEmpty: false, "(", block.arguments, ", ", ")") { print($0) }
        print(":")
        indent()
        print(block.operatorDefs) { print("\n"); print($0) }
        print("\n")
        print(block.terminatorDef)
        print("\n")
        unindent()
    }

    func print(_ operatorDef: OperatorDef) {
        print(operatorDef.result, " = ") { print($0) }
        print(operatorDef.operator)
        print(operatorDef.sourceInfo) { print($0) }
    }

    func print(_ terminatorDef: TerminatorDef) {
        print(terminatorDef.terminator)
        print(terminatorDef.sourceInfo) { print($0) }
    }

    func print(_ op: Operator) {
        switch op {
        case let .allocStack(type, attributes):
            print("alloc_stack ")
            print(type)
            print(whenEmpty: false, ", ", attributes, ", ", "") { print($0) }
        case let .apply(nothrow, value, substitutions, arguments, type):
            print("apply ")
            print(when: nothrow, "[nothrow] ")
            print(value)
            print(whenEmpty: false, "<", substitutions, ", ", ">") { naked($0) }
            print("(", arguments, ", ", ")") { print($0) }
            print(" : ")
            print(type)
        case let .beginAccess(access, enforcement, noNestedConflict, builtin, operand):
            print("begin_access ")
            print("[")
            print(access)
            print("] ")
            print("[")
            print(enforcement)
            print("] ")
            print(when: noNestedConflict, "[noNestedConflict] ")
            print(when: builtin, "[builtin] ")
            print(operand)
        case let .beginApply(nothrow, value, substitutions, arguments, type):
            print("begin_apply ")
            print(when: nothrow, "[nothrow] ")
            print(value)
            print(whenEmpty: false, "<", substitutions, ", ", ">") { naked($0) }
            print("(", arguments, ", ", ")") { print($0) }
            print(" : ")
            print(type)
        case let .beginBorrow(operand):
            print("begin_borrow ")
            print(operand)
        case let .builtin(name, operands, type):
            print("builtin ")
            literal(name)
            print("(", operands, ", ", ")") { print($0) }
            print(" : ")
            print(type)
        case let .condFail(operand, message):
            print("cond_fail ")
            print(operand)
            print(", ")
            literal(message)
        case let .convertEscapeToNoescape(notGuaranteed, escaped, operand, type):
            print("convert_escape_to_noescape ")
            print(when: notGuaranteed, "[not_guaranteed] ")
            print(when: escaped, "[escaped] ")
            print(operand)
            print(" to ")
            print(type)
        case let .convertFunction(operand, withoutActuallyEscaping, type):
            print("convert_function ")
            print(operand)
            print(" to ")
            print(when: withoutActuallyEscaping, "[without_actually_escaping] ")
            print(type)
        case let .copyAddr(take, value, initialization, operand):
            print("copy_addr ")
            print(when: take, "[take] ")
            print(value)
            print(" to ")
            print(when: initialization, "[initialization] ")
            print(operand)
        case let .copyValue(operand):
            print("copy_value ")
            print(operand)
        case let .deallocStack(operand):
            print("dealloc_stack ")
            print(operand)
        case let .debugValue(operand, attributes):
            print("debug_value ")
            print(operand)
            print(whenEmpty: false, ", ", attributes, ", ", "") { print($0) }
        case let .debugValueAddr(operand, attributes):
            print("debug_value_addr ")
            print(operand)
            print(whenEmpty: false, ", ", attributes, ", ", "") { print($0) }
        case let .destroyValue(operand):
            print("destroy_value ")
            print(operand)
        case let .destructureTuple(operand):
            print("destructure_tuple ")
            print(operand)
        case let .endAccess(abort, operand):
            print("end_access ")
            print(when: abort, "[abort] ")
            print(operand)
        case let .endApply(value):
            print("end_apply ")
            print(value)
        case let .endBorrow(value):
            print("end_borrow ")
            print(value)
        case let .enum(type, declRef, maybeOperand):
            print("enum ")
            print(type)
            print(", ")
            print(declRef)
            if let operand = maybeOperand {
              print(", ")
              print(operand)
            }
        case let .floatLiteral(type, value):
            print("float_literal ")
            print(type)
            print(", 0x")
            print(value)
        case let .functionRef(name, type):
            print("function_ref ")
            print("@")
            print(name)
            print(" : ")
            print(type)
        case let .globalAddr(name, type):
            print("global_addr ")
            print("@")
            print(name)
            print(" : ")
            print(type)
        case let .indexAddr(addr, index):
            print("index_addr ")
            print(addr)
            print(", ")
            print(index)
        case let .integerLiteral(type, value):
            print("integer_literal ")
            print(type)
            print(", ")
            literal(value)
        case let .load(maybeOwnership, operand):
            print("load ")
            if let ownership = maybeOwnership {
                print(ownership)
                print(" ")
            }
            print(operand)
        case let .markDependence(operand, on):
            print("mark_dependence ")
            print(operand)
            print(" on ")
            print(on)
        case let .metatype(type):
            print("metatype ")
            print(type)
        case let .partialApply(calleeGuaranteed, onStack, value, substitutions, arguments, type):
            print("partial_apply ")
            print(when: calleeGuaranteed, "[callee_guaranteed] ")
            print(when: onStack, "[on_stack] ")
            print(value)
            print(whenEmpty: false, "<", substitutions, ", ", ">") { naked($0) }
            print("(", arguments, ", ", ")") { print($0) }
            print(" : ")
            print(type)
        case let .pointerToAddress(operand, strict, type):
            print("pointer_to_address ")
            print(operand)
            print(" to ")
            print(when: strict, "[strict] ")
            print(type)
        case let .releaseValue(operand):
            print("release_value ")
            print(operand)
        case let .retainValue(operand):
            print("retain_value ")
            print(operand)
        case let .selectEnum(operand, cases, type):
            print("select_enum ")
            print(operand)
            print(whenEmpty: false, "", cases, "", "") { print($0) }
            print(" : ")
            print(type)
        case let .store(value, maybeOwnership, operand):
            print("store ")
            print(value)
            print(" to ")
            if let ownership = maybeOwnership {
                print(ownership)
                print(" ")
            }
            print(operand)
        case let .stringLiteral(encoding, value):
            print("string_literal ")
            print(encoding)
            print(" ")
            literal(value)
        case let .strongRelease(operand):
            print("strong_release ")
            print(operand)
        case let .strongRetain(operand):
            print("strong_retain ")
            print(operand)
        case let .struct(type, operands):
            print("struct ")
            print(type)
            print(" (", operands, ", ", ")") { print($0) }
        case let .structElementAddr(operand, declRef):
            print("struct_element_addr ")
            print(operand)
            print(", ")
            print(declRef)
        case let .structExtract(operand, declRef):
            print("struct_extract ")
            print(operand)
            print(", ")
            print(declRef)
        case let .thinToThickFunction(operand, type):
            print("thin_to_thick_function ")
            print(operand)
            print(" to ")
            print(type)
        case let .tuple(elements):
            print("tuple ")
            print(elements)
        case let .tupleExtract(operand, declRef):
            print("tuple_extract ")
            print(operand)
            print(", ")
            literal(declRef)
        case let .unknown(name):
            print(name)
            print(" <?>")
        case let .witnessMethod(archeType, declRef, declType, type):
            print("witness_method ")
            print(archeType)
            print(", ")
            print(declRef)
            print(" : ")
            naked(declType)
            print(" : ")
            print(type)
        }
    }

    func print(_ terminator: Terminator) {
      switch terminator {
        case let .br(label, operands):
            print("br ")
            print(label)
            print(whenEmpty: false, "(", operands, ", ", ")") { print($0) }
        case let .condBr(cond, trueLabel, trueOperands, falseLabel, falseOperands):
            print("cond_br ")
            print(cond)
            print(", ")
            print(trueLabel)
            print(whenEmpty: false, "(", trueOperands, ", ", ")") { print($0) }
            print(", ")
            print(falseLabel)
            print(whenEmpty: false, "(", falseOperands, ", ", ")") { print($0) }
        case let .return(operand):
            print("return ")
            print(operand)
        case let .switchEnum(operand, cases):
            print("switch_enum ")
            print(operand)
            print(whenEmpty: false, "", cases, "", "") { print($0) }
        case let .unknown(name):
            print(name)
            print(" <?>")
        case .unreachable:
            print("unreachable")
      }
    }

    // MARK: Auxiliary data structures

    func print(_ access: Access) {
        switch access {
        case .deinit:
            print("deinit")
        case .`init`:
            print("init")
        case .modify:
            print("modify")
        case .read:
            print("read")
        }
    }

    func print(_ argument: Argument) {
        print(argument.valueName)
        print(" : ")
        print(argument.type)
    }

    func print(_ `case`: Case) {
        print(", ")
        switch `case` {
        case let .case(declRef, result):
            print("case ")
            print(declRef)
            print(": ")
            print(result)
        case let .default(result):
            print("default ")
            print(result)
        }
    }

    func print(_ convention: Convention) {
        print("(")
        switch convention {
        case .c:
            print("c")
        case .method:
            print("method")
        case .thin:
            print("thin")
        case let .witnessMethod(type):
            print("witness_method: ")
            naked(type)
        }
        print(")")
    }

    func print(_ attribute: DebugAttribute) {
        switch attribute {
        case let .argno(name):
            print("argno ")
            literal(name)
        case let .name(name):
            print("name ")
            literal(name)
        case .let:
            print("let")
        case .var:
            print("var")
        }
    }

    func print(_ declKind: DeclKind) {
        switch declKind {
        case .allocator:
            print("allocator")
        case .deallocator:
            print("deallocator")
        case .destroyer:
            print("destroyer")
        case .enumElement:
            print("enumelt")
        case .getter:
            print("getter")
        case .globalAccessor:
            print("globalaccessor")
        case .initializer:
            print("initializer")
        case .ivarDestroyer:
            print("ivardestroyer")
        case .ivarInitializer:
            print("ivarinitializer")
        case .setter:
            print("setter")
        }
    }

    func print(_ declRef: DeclRef) {
        print("#")
        print(declRef.name.joined(separator: "."))
        if let kind = declRef.kind {
            print("!")
            print(kind)
        }
        if let level = declRef.level {
            print(declRef.kind == nil ? "!" : ".")
            literal(level)
        }
    }

    func print(_ encoding: Encoding) {
        switch encoding {
        case .objcSelector:
            print("objcSelector")
        case .utf8:
            print("utf8")
        case .utf16:
            print("utf16")
        }
    }

    func print(_ enforcement: Enforcement) {
        switch enforcement {
        case .dynamic:
            print("dynamic")
        case .static:
            print("static")
        case .unknown:
            print("unknown")
        case .unsafe:
            print("unsafe")
        }
    }

    func print(_ attribute: FunctionAttribute) {
        switch attribute {
        case .alwaysInline:
            print("[always_inline]")
        case let .differentiable(spec):
            print("[differentiable ")
            print(spec)
            print("]")
        case .dynamicallyReplacable:
            print("[dynamically_replacable]")
        case .noInline:
            print("[noinline]")
        case .noncanonical(.ownershipSSA):
            print("[ossa]")
        case .readonly:
            print("[readonly]")
        case let .semantics(value):
            print("[_semantics ")
            literal(value)
            print("]")
        case .serialized:
            print("[serialized]")
        case .thunk:
            print("[thunk]")
        case .transparent:
            print("[transparent]")
        }
    }

    func print(_ linkage: Linkage) {
        switch linkage {
        case .hidden:
            print("hidden ")
        case .hiddenExternal:
            print("hidden_external ")
        case .private:
            print("private ")
        case .privateExternal:
            print("private_external ")
        case .public:
            print("")
        case .publicExternal:
            print("public_external ")
        case .publicNonABI:
            print("non_abi ")
        case .shared:
            print("shared ")
        case .sharedExternal:
            print("shared_external ")
        }
    }

    func print(_ loc: Loc) {
        print("loc ")
        literal(loc.path)
        print(":")
        literal(loc.line)
        print(":")
        literal(loc.column)
    }

    func print(_ operand: Operand) {
        print(operand.value)
        print(" : ")
        print(operand.type)
    }

    func print(_ result: Result) {
        if result.valueNames.count == 1 {
            print(result.valueNames[0])
        } else {
            print("(", result.valueNames, ", ", ")") { print($0) }
        }
    }

    func print(_ sourceInfo: SourceInfo) {
        // NB: The SIL docs say that scope refs precede locations, but this is
        //     not true once you look at the compiler outputs or its source code.
        print(", ", sourceInfo.loc) { print($0) }
        print(", scope ", sourceInfo.scopeRef) { print($0) }
    }

    func print(_ elements: TupleElements) {
        switch elements {
        case let .labeled(type, values):
            print(type)
            print(" (", values, ", ", ")") { print($0) }
        case let .unlabeled(operands):
            print("(", operands, ", ", ")") { print($0) }
        }
    }

    func print(_ type: Type) {
        if case let .withOwnership(attr, subtype) = type {
          print(attr)
          print(" ")
          print(subtype)
        } else {
          print("$")
          naked(type)
        }
    }

    func naked(_ type: Type) {
        switch type {
        case let .addressType(type):
            print("*")
            naked(type)
        case let .attributedType(attrs, type):
            print("", attrs, " ", " ") { print($0) }
            naked(type)
        case .coroutineTokenType:
            print("!CoroutineTokenType!")
        case let .functionType(params, result):
            print("(", params, ", ", ")") { naked($0) }
            print(" -> ")
            naked(result)
        case let .genericType(params, reqs, type):
            print("<", params, ", ", "") { print($0) }
            print(whenEmpty: false, " where ", reqs, ", ", "") { print($0) }
            print(">")
            // This is a weird corner case of -emit-sil, so we have to go the extra mile.
            if case .genericType = type {
                naked(type)
            } else {
                print(" ")
                naked(type)
            }
        case let .namedType(name):
            print(name)
        case let .selectType(type, name):
            naked(type)
            print(".")
            print(name)
        case .selfType:
            print("Self")
        case let .specializedType(type, args):
            naked(type)
            print("<", args, ", ", ">") { naked($0) }
        case let .tupleType(params):
            print("(", params, ", ", ")") { naked($0) }
        case .withOwnership(_, _):
            fatalError("Types with ownership should be printed before naked type print!")
        }
    }

    func print(_ attribute: TypeAttribute) {
        switch attribute {
        case .calleeGuaranteed:
            print("@callee_guaranteed")
        case let .convention(convention):
            print("@convention")
            print(convention)
        case .guaranteed:
            print("@guaranteed")
        case .inGuaranteed:
            print("@in_guaranteed")
        case .in:
            print("@in")
        case .inout:
            print("@inout")
        case .noescape:
            print("@noescape")
        case .out:
            print("@out")
        case .owned:
            print("@owned")
        case .thick:
            print("@thick")
        case .thin:
            print("@thin")
        case .yieldOnce:
            print("@yield_once")
        case .yields:
            print("@yields")
        }
    }

    func print(_ requirement: TypeRequirement) {
        switch requirement {
        case let .conformance(lhs, rhs):
            naked(lhs)
            print(" : ")
            naked(rhs)
        case let .equality(lhs, rhs):
            naked(lhs)
            print(" == ")
            naked(rhs)
        }
    }

    func print(_ ownership: LoadOwnership) {
        switch ownership {
        case .copy: print("[copy]")
        case .take: print("[take]")
        case .trivial: print("[trivial]")
        }
    }

    func print(_ ownership: StoreOwnership) {
        switch ownership {
        case .`init`: print("[init]")
        case .trivial: print("[trivial]")
        }
    }
}

extension Module: CustomStringConvertible {
    public var description: String {
        let p = SILPrinter()
        p.print(self)
        return p.description
    }
}

extension Function: CustomStringConvertible {
    public var description: String {
        let p = SILPrinter()
        p.print(self)
        return p.description
    }
}

extension Block: CustomStringConvertible {
    public var description: String {
        let p = SILPrinter()
        p.print(self)
        return p.description
    }
}

extension OperatorDef: CustomStringConvertible {
    public var description: String {
        let p = SILPrinter()
        p.print(self)
        return p.description
    }
}

extension TerminatorDef: CustomStringConvertible {
    public var description: String {
        let p = SILPrinter()
        p.print(self)
        return p.description
    }
}

extension InstructionDef: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .operator(def): return def.description
        case let .terminator(def): return def.description
        }
    }
}

extension Operator: CustomStringConvertible {
    public var description: String {
        let p = SILPrinter()
        p.print(self)
        return p.description
    }
}

extension Terminator: CustomStringConvertible {
    public var description: String {
        let p = SILPrinter()
        p.print(self)
        return p.description
    }
}

extension Instruction: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .operator(def): return def.description
        case let .terminator(def): return def.description
        }
    }
}

