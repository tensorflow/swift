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
        print(":\n")
        indent()
        print(block.instructionDefs, "\n") { print($0) }
        print("\n")
        unindent()
    }

    func print(_ instructionDef: InstructionDef) {
        print(instructionDef.result, " = ") { print($0) }
        print(instructionDef.instruction)
        print(instructionDef.sourceInfo) { print($0) }
    }

    func print(_ instruction: Instruction) {
        switch instruction {
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
        case let .br(label, operands):
            print("br ")
            print(label)
            print(whenEmpty: false, " (", operands, ", ", ")") { print($0) }
        case let .builtin(name, operands, type):
            print("builtin ")
            literal(name)
            print("(", operands, ", ", ")") { print($0) }
            print(" : ")
            print(type)
        case let .condBr(cond, trueLabel, trueOperands, falseLabel, falseOperands):
            print("cond_br ")
            print(cond)
            print(", ")
            print(trueLabel)
            print(whenEmpty: false, " (", trueOperands, ", ", ")") { print($0) }
            print(", ")
            print(falseLabel)
            print(whenEmpty: false, " (", falseOperands, ", ", ")") { print($0) }
        case let .condFail(operand, message):
            print("cond_fail ")
            print(operand)
            print(", ")
            literal(message)
        case let .copyAddr(take, value, initialization, operand):
            print("copy_addr ")
            print(when: take, "[take] ")
            print(value)
            print(" to ")
            print(when: initialization, "[initialization] ")
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
        case let .endAccess(abort, operand):
            print("end_access ")
            print(when: abort, "[abort] ")
            print(operand)
        case let .endApply(value):
            print("end_apply ")
            print(value)
        case let .floatLiteral(type, value):
            print("float_literal ")
            print(type)
            print(", ")
            hex(value)
        case let .functionRef(name, type):
            print("function_ref ")
            print("@")
            print(name)
            print(" : ")
            print(type)
        case let .integerLiteral(type, value):
            print("integer_literal ")
            print(type)
            print(", ")
            literal(value)
        case let .load(operand):
            print("load ")
            print(operand)
        case let .metatype(type):
            print("metatype ")
            print(type)
        case let .return(operand):
            print("return ")
            print(operand)
        case let .store(value, operand):
            print("store ")
            print(value)
            print(" to ")
            print(operand)
        case let .stringLiteral(encoding, value):
            print("string_literal ")
            print(encoding)
            print(" ")
            literal(value)
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
        case let .switchEnum(operand, cases):
            print("switch_enum ")
            print(operand)
            print(whenEmpty: false, "", cases, "", "") { print($0) }
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
        case .unreachable:
            print("unreachable")
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
        case let .case(declRef, identifier):
            print("case ")
            print(declRef)
            print(": ")
            print(identifier)
        case let .default(identifier):
            print("default ")
            print(identifier)
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
        case .enumElement:
            print("enumelt")
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
        case .noInline:
            print("[noinline]")
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
        case .public:
            print("")
        case .publicExternal:
            print("public_external ")
        case .sharedExternal:
            print("shared_external ")
        }
    }

    func print(_ loc: Loc) {
        print("loc ")
        literal(loc.path)
        print(" : ")
        literal(loc.line)
        print(" : ")
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
        print(", ", sourceInfo.scopeRef) { print($0) }
        print(", ", sourceInfo.loc) { print($0) }
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
        print("$")
        naked(type)
    }

    func naked(_ type: Type) {
        switch type {
        case let .addressType(type):
            print("*")
            naked(type)
        case let .attributedType(attrs, type):
            print("", attrs, " ", " ") { print($0) }
            naked(type)
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

extension InstructionDef: CustomStringConvertible {
    public var description: String {
        let p = SILPrinter()
        p.print(self)
        return p.description
    }
}

extension Instruction: CustomStringConvertible {
    public var description: String {
        let p = SILPrinter()
        p.print(self)
        return p.description
    }
}
