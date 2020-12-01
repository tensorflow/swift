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

class SILParser: Parser {
    // https://github.com/apple/swift/blob/main/docs/SIL.rst#syntax
    func parseModule() throws -> Module {
        var functions = [Function]()
        while true {
            // TODO(#8): Parse sections of SIL printouts that don't start with "sil @".
            // Meanwhile, skip those sections since we don't have a representation for them yet.
            // Concretely: if the current line begins with "sil @", try to parse a Function.
            // Otherwise, skip to the end of line and repeat.
            if peek("sil ") {
                let function = try parseFunction()
                functions.append(function)
            } else {
                guard !skip(while: { $0 != "\n" }) else { continue }
                return Module(functions)
            }
        }
    }

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#functions
    func parseFunction() throws -> Function {
        try take("sil")
        let linkage = try parseLinkage()
        let attributes = try parseNilOrMany("[") { try parseFunctionAttribute() } ?? []
        let name = try parseGlobalName()
        try take(":")
        let type = try parseType()
        let blocks = try parseNilOrMany("{", "", "}") { try parseBlock() } ?? []
        return Function(linkage, attributes, name, type, blocks)
    }

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#basic-blocks
    func parseBlock() throws -> Block {
        let identifier = try parseIdentifier()
        let arguments = try parseNilOrMany("(", ",", ")") { try parseArgument() } ?? []
        try take(":")
        let (operatorDefs, terminatorDef) = try parseInstructionDefs()
        return Block(identifier, arguments, operatorDefs, terminatorDef)
    }

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#basic-blocks
    func parseInstructionDefs() throws -> ([OperatorDef], TerminatorDef) {
        var operatorDefs = [OperatorDef]()
        while true {
            switch try parseInstructionDef() {
            case let .operator(operatorDef):
                operatorDefs.append(operatorDef)
            case let .terminator(terminatorDef):
                return (operatorDefs, terminatorDef)
            }
            if peek("bb") || peek("}") {
                guard case let .unknown(instructionName) = operatorDefs.popLast()?.operator else {
                    throw parseError("block is missing a terminator")
                }
                return (operatorDefs, TerminatorDef(.unknown(instructionName), nil))
            }
        }
    }

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#basic-blocks
    func parseInstructionDef() throws -> InstructionDef {
        let result = try parseResult()
        let body = parseInstruction()
        let sourceInfo = try parseSourceInfo()
        switch body {
        case let .operator(op):
            return .operator(OperatorDef(result, op, sourceInfo))
        case let .terminator(terminator):
            guard result == nil else {
              throw parseError("terminator instruction shouldn't have any results")
            }
            return .terminator(TerminatorDef(terminator, sourceInfo))
        }
    }

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#instruction-set
    func parseInstruction() -> Instruction {
        let instructionName = take(while: { $0.isLetter || $0 == "_" })
        do {
            return try parseInstructionBody(instructionName)
        } catch {
            // Try to recover to a point where resuming the parsing is sensible
            // by skipping until the end of this line. This is only a heuristic:
            // I don't think that the SIL specification guarantees that.
            let _ = skip(while: { $0 != "\n" })
            return .operator(.unknown(instructionName))
        }
    }

    func parseInstructionBody(_ instructionName: String) throws -> Instruction {
        switch instructionName {
        case "alloc_stack":
            let type = try parseType()
            let attributes = try parseUntilNil { try parseDebugAttribute() }
            return .operator(.allocStack(type, attributes))
        case "apply":
            let nothrow = skip("[nothrow]")
            let value = try parseValue()
            let substitutions = try parseNilOrMany("<", ",", ">") { try parseNakedType() } ?? []
            let arguments = try parseMany("(", ",", ")") { try parseValue() }
            try take(":")
            let type = try parseType()
            return .operator(.apply(nothrow, value, substitutions, arguments, type))
        case "begin_access":
            try take("[")
            let access = try parseAccess()
            try take("]")
            try take("[")
            let enforcement = try parseEnforcement()
            try take("]")
            let noNestedConflict = skip("[no_nested_conflict]")
            let builtin = skip("[builtin]")
            let operand = try parseOperand()
            return .operator(.beginAccess(access, enforcement, noNestedConflict, builtin, operand))
        case "begin_apply":
            let nothrow = skip("[nothrow]")
            let value = try parseValue()
            let substitutions = try parseNilOrMany("<", ",", ">") { try parseNakedType() } ?? []
            let arguments = try parseMany("(", ",", ")") { try parseValue() }
            try take(":")
            let type = try parseType()
            return .operator(.beginApply(nothrow, value, substitutions, arguments, type))
        case "begin_borrow":
            let operand = try parseOperand()
            return .operator(.beginBorrow(operand))
        case "br":
            let label = try parseIdentifier()
            let operands = try parseNilOrMany("(", ",", ")") { try parseOperand() } ?? []
            return .terminator(.br(label, operands))
        case "builtin":
            let name = try parseString()
            let operands = try parseMany("(", ",", ")") { try parseOperand() }
            try take(":")
            let type = try parseType()
            return .operator(.builtin(name, operands, type))
        case "cond_br":
            let cond = try parseValueName()
            try take(",")
            let trueLabel = try parseIdentifier()
            let trueOperands = try parseNilOrMany("(", ",", ")") { try parseOperand() } ?? []
            try take(",")
            let falseLabel = try parseIdentifier()
            let falseOperands = try parseNilOrMany("(", ",", ")") { try parseOperand() } ?? []
            return .terminator(.condBr(cond, trueLabel, trueOperands, falseLabel, falseOperands))
        case "cond_fail":
            let operand = try parseOperand()
            try take(",")
            let message = try parseString()
            return .operator(.condFail(operand, message))
        case "convert_escape_to_noescape":
            let notGuaranteed = skip("[not_guaranteed]")
            let escaped = skip("[escaped]")
            let operand = try parseOperand()
            try take("to")
            let type = try parseType()
            return .operator(.convertEscapeToNoescape(notGuaranteed, escaped, operand, type))
        case "convert_function":
            let operand = try parseOperand()
            try take("to")
            let withoutActuallyEscaping = skip("[without_actually_escaping]")
            let type = try parseType()
            return .operator(.convertFunction(operand, withoutActuallyEscaping, type))
        case "copy_addr":
            let take = skip("[take]")
            let value = try parseValue()
            try self.take("to")
            let initialization = skip("[initialization]")
            let operand = try parseOperand()
            return .operator(.copyAddr(take, value, initialization, operand))
        case "copy_value":
            let operand = try parseOperand()
            return .operator(.copyValue(operand))
        case "dealloc_stack":
            let operand = try parseOperand()
            return .operator(.deallocStack(operand))
        case "debug_value":
            let operand = try parseOperand()
            let attributes = try parseUntilNil { try parseDebugAttribute() }
            return .operator(.debugValue(operand, attributes))
        case "debug_value_addr":
            let operand = try parseOperand()
            let attributes = try parseUntilNil { try parseDebugAttribute() }
            return .operator(.debugValueAddr(operand, attributes))
        case "destroy_value":
            let operand = try parseOperand()
            return .operator(.destroyValue(operand))
        case "destructure_tuple":
            let operand = try parseOperand()
            return .operator(.destructureTuple(operand))
        case "end_access":
            let abort = skip("[abort]")
            let operand = try parseOperand()
            return .operator(.endAccess(abort, operand))
        case "end_apply":
            let value = try parseValue()
            return .operator(.endApply(value))
        case "end_borrow":
            let operand = try parseOperand()
            return .operator(.endBorrow(operand))
        case "enum":
            let type = try parseType()
            try take(",")
            let declRef = try parseDeclRef()
            let operand = skip(",") ? try parseOperand() : nil
            return .operator(.enum(type, declRef, operand))
        case "float_literal":
            let type = try parseType()
            try take(",")
            try take("0x")
            let value = take(while: { $0.isHexDigit })
            return .operator(.floatLiteral(type, value))
        case "function_ref":
            let name = try parseGlobalName()
            try take(":")
            let type = try parseType()
            return .operator(.functionRef(name, type))
        case "global_addr":
            let name = try parseGlobalName()
            try take(":")
            let type = try parseType()
            return .operator(.globalAddr(name, type))
        case "index_addr":
            let addr = try parseOperand()
            try take(",")
            let index = try parseOperand()
            return .operator(.indexAddr(addr, index))
        case "integer_literal":
            let type = try parseType()
            try take(",")
            let value = try parseInt()
            return .operator(.integerLiteral(type, value))
        case "load":
            var ownership: LoadOwnership?
            if skip("[copy]") {
                ownership = .copy
            } else if skip("[take]") {
                ownership = .take
            } else if skip("[trivial]") {
                ownership = .trivial
            }
            let operand = try parseOperand()
            return .operator(.load(ownership, operand))
        case "metatype":
            let type = try parseType()
            return .operator(.metatype(type))
        case "mark_dependence":
            let operand = try parseOperand()
            try take("on")
            let on = try parseOperand()
            return .operator(.markDependence(operand, on))
        case "partial_apply":
            let calleeGuaranteed = skip("[callee_guaranteed]")
            let onStack = skip("[on_stack]")
            let value = try parseValue()
            let substitutions = try parseNilOrMany("<", ",", ">") { try parseNakedType() } ?? []
            let arguments = try parseMany("(", ",", ")") { try parseValue() }
            try take(":")
            let type = try parseType()
            return .operator(.partialApply(calleeGuaranteed, onStack, value, substitutions, arguments, type))
        case "pointer_to_address":
            let operand = try parseOperand()
            try take("to")
            let strict = skip("[strict]")
            let type = try parseType()
            return .operator(.pointerToAddress(operand, strict, type))
        case "return":
            let operand = try parseOperand()
            return .terminator(.return(operand))
        case "release_value":
            let operand = try parseOperand()
            return .operator(.releaseValue(operand))
        case "retain_value":
            let operand = try parseOperand()
            return .operator(.retainValue(operand))
        case "select_enum":
            let operand = try parseOperand()
            let cases = try parseUntilNil { try parseCase(parseValue) }
            try take(":")
            let type = try parseType()
            return .operator(.selectEnum(operand, cases, type))
        case "store":
            let value = try parseValue()
            try take("to")
            var ownership: StoreOwnership?
            if skip("[init]") {
                ownership = .init
            } else if skip("[trivial]") {
                ownership = .trivial
            }
            let operand = try parseOperand()
            return .operator(.store(value, ownership, operand))
        case "string_literal":
            let encoding = try parseEncoding()
            let value = try parseString()
            return .operator(.stringLiteral(encoding, value))
        case "strong_release":
            let operand = try parseOperand()
            return .operator(.strongRelease(operand))
        case "strong_retain":
            let operand = try parseOperand()
            return .operator(.strongRetain(operand))
        case "struct":
            let type = try parseType()
            let operands = try parseMany("(", ",", ")") { try parseOperand() }
            return .operator(.struct(type, operands))
        case "struct_element_addr":
            let operand = try parseOperand()
            try take(",")
            let declRef = try parseDeclRef()
            return .operator(.structElementAddr(operand, declRef))
        case "struct_extract":
            let operand = try parseOperand()
            try take(",")
            let declRef = try parseDeclRef()
            return .operator(.structExtract(operand, declRef))
        case "switch_enum":
            let operand = try parseOperand()
            let cases = try parseUntilNil { try parseCase(parseIdentifier) }
            return .terminator(.switchEnum(operand, cases))
        case "thin_to_thick_function":
            let operand = try parseOperand()
            try take("to")
            let type = try parseType()
            return .operator(.thinToThickFunction(operand, type))
        case "tuple":
            let elements = try parseTupleElements()
            return .operator(.tuple(elements))
        case "tuple_extract":
            let operand = try parseOperand()
            try take(",")
            let declRef = try parseInt()
            return .operator(.tupleExtract(operand, declRef))
        case "unreachable":
            return .terminator(.unreachable)
        case "witness_method":
            let archeType = try parseType()
            try take(",")
            let declRef = try parseDeclRef()
            try take(":")
            let declType = try parseNakedType()
            try take(":")
            let type = try parseType()
            return .operator(.witnessMethod(archeType, declRef, declType, type))
        default:
            // TODO(#8): Actually parse this instruction.
            let _ = skip(while: { $0 != "\n" })
            return .operator(.unknown(instructionName))
        }
    }

    // MARK: Auxiliary data structures

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#begin-access
    func parseAccess() throws -> Access {
        guard !skip("deinit") else { return .deinit }
        guard !skip("init") else { return .`init` }
        guard !skip("modify") else { return .modify }
        guard !skip("read") else { return .read }
        throw parseError("unknown access")
    }

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#basic-blocks
    func parseArgument() throws -> Argument {
        let valueName = try parseValueName()
        try take(":")
        let type = try parseType()
        return Argument(valueName, type)
    }

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#switch-enum
    func parseCase(_ parseElement: () throws -> String) throws -> Case? {
        return try maybeParse {
            guard skip(",") else { return nil }
            if skip("case") {
                let declRef = try parseDeclRef()
                try take(":")
                let identifier = try parseElement()
                return .case(declRef, identifier)
            } else if skip("default") {
                let identifier = try parseElement()
                return .default(identifier)
            } else {
                return nil
            }
        }
    }

    func parseConvention() throws -> Convention {
        try take("(")
        let result: Convention
        if skip("c") {
            result = .c
        } else if skip("method") {
            result = .method
        } else if skip("thin") {
            result = .thin
        } else if skip("witness_method") {
            try take(":")
            let type = try parseNakedType()
            result = .witnessMethod(type)
        } else {
            throw parseError("unknown convention")
        }
        try take(")")
        return result
    }

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#debug-value
    func parseDebugAttribute() throws -> DebugAttribute? {
        return try maybeParse {
            guard skip(",") else { return nil }
            guard !skip("argno") else { return .argno(try parseInt()) }
            guard !skip("name") else { return .name(try parseString()) }
            guard !skip("let") else { return .let }
            guard !skip("var") else { return .var }
            return nil
        }
    }

    func parseDeclKind() throws -> DeclKind? {
        guard !skip("allocator") else { return .allocator }
        guard !skip("deallocator") else { return .deallocator }
        guard !skip("destroyer") else { return .destroyer }
        guard !skip("enumelt") else { return .enumElement }
        guard !skip("getter") else { return .getter }
        guard !skip("globalaccessor") else { return .globalAccessor }
        guard !skip("initializer") else { return .initializer }
        guard !skip("ivardestroyer") else { return .ivarDestroyer }
        guard !skip("ivarinitializer") else { return .ivarInitializer }
        guard !skip("setter") else { return .setter }
        return nil
    }

    func parseDeclRef() throws -> DeclRef {
        try take("#")
        var name = [String]()
        while true {
            let identifier = try parseIdentifier()
            name.append(identifier)
            guard skip(".") else { break }
        }
        guard skip("!") else { return DeclRef(name, nil, nil) }
        let kind = try parseDeclKind()
        guard kind == nil || skip(".") else { return DeclRef(name, kind, nil) }
        let level = try parseInt()
        return DeclRef(name, kind, level)
    }

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#string-literal
    func parseEncoding() throws -> Encoding {
        guard !skip("objc_selector") else { return .objcSelector }
        guard !skip("utf8") else { return .utf8 }
        guard !skip("utf16") else { return .utf16 }
        throw parseError("unknown encoding")
    }

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#begin-access
    func parseEnforcement() throws -> Enforcement {
        guard !skip("dynamic") else { return .dynamic }
        guard !skip("static") else { return .static }
        guard !skip("unknown") else { return .unknown }
        guard !skip("unsafe") else { return .unsafe }
        throw parseError("unknown enforcement")
    }

    // Reverse-engineered from -emit-sil
    func parseFunctionAttribute() throws -> FunctionAttribute {
        func parseDifferentiable() throws -> FunctionAttribute {
            try take("[differentiable")
            let spec = take(while: { $0 != "]" })
            try take("]")
            return .differentiable(spec)
        }
        func parseSemantics() throws -> FunctionAttribute {
            try take("[_semantics")
            let value = try parseString()
            try take("]")
            return .semantics(value)
        }
        guard !skip("[always_inline]") else { return .alwaysInline }
        guard !peek("[differentiable") else { return try parseDifferentiable() }
        guard !skip("[dynamically_replacable]") else { return .dynamicallyReplacable }
        guard !skip("[noinline]") else { return .noInline }
        guard !skip("[ossa]") else { return .noncanonical(.ownershipSSA) }
        guard !skip("[readonly]") else { return .readonly }
        guard !peek("[_semantics") else { return try parseSemantics() }
        guard !skip("[serialized]") else { return .serialized }
        guard !skip("[thunk]") else { return .thunk }
        guard !skip("[transparent]") else { return .transparent }
        throw parseError("unknown function attribute")
    }

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#functions
    func parseGlobalName() throws -> String {
        let start = position
        if skip("@") {
            // TODO(#14): Make name parsing more thorough.
            let name = take(while: { $0 == "$" || $0.isLetter || $0.isNumber || $0 == "_" })
            if !name.isEmpty {
                return name
            }
        }
        throw parseError("function name expected", at: start)
    }

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#values-and-operands
    func parseIdentifier() throws -> String {
        if peek("\"") {
            return "\"\(try parseString())\""
        } else {
            let start = position
            // TODO(#14): Make name parsing more thorough.
            let identifier = take(while: { $0.isLetter || $0.isNumber || $0 == "_" })
            if !identifier.isEmpty {
                return identifier
            }
            throw parseError("identifier expected", at: start)
        }
    }

    func parseInt() throws -> Int {
        // TODO(#26): Make number parsing more thorough.
        let start = position
        let radix = skip("0x") ? 16 : 10
        let s = take(while: { $0 == "-" || $0 == "+" || $0.isHexDigit })
        guard let value = Int(s, radix: radix) else {
            throw parseError("integer literal expected", at: start)
        }
        return value
    }

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#linkage
    func parseLinkage() throws -> Linkage {
        // The order in here is a bit relaxed because longer words need to come
        // before the shorter ones to parse correctly.
        guard !skip("hidden_external") else { return .hiddenExternal }
        guard !skip("hidden") else { return .hidden }
        guard !skip("private_external") else { return .privateExternal }
        guard !skip("private") else { return .private }
        guard !skip("public_external") else { return .publicExternal }
        guard !skip("non_abi") else { return .publicNonABI }
        guard !skip("public") else { return .public }
        guard !skip("shared_external") else { return .sharedExternal }
        guard !skip("shared") else { return .shared }
        return .public
    }

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#debug-information
    func parseLoc() throws -> Loc? {
        guard skip("loc") else { return nil }
        let path = try parseString()
        try take(":")
        let line = try parseInt()
        try take(":")
        let column = try parseInt()
        return Loc(path, line, column)
    }

    // Parses verbatim string representation of a type.
    // This is different from `parseType` because most usages of types in SIL are prefixed with
    // `$` (so it made sense to have a shorter name for that common case).
    // Type format has been reverse-engineered since it doesn't seem to be mentioned in the spec.
    func parseNakedType() throws -> Type {
        if skip("<") {
            var params = [String]()
            while true {
                let name = try parseTypeName()
                params.append(name)
                guard !peek("where") && !peek(">") else { break }
                try take(",")
            }
            let reqs: [TypeRequirement]
            if peek("where") {
                reqs = try parseMany("where", ",", ">") { try parseTypeRequirement() }
            } else {
                reqs = []
                try take(">")
            }
            let type = try parseNakedType()
            return .genericType(params, reqs, type)
        } else if peek("@") {
            let attrs = try parseMany("@") { try parseTypeAttribute() }
            let type = try parseNakedType()
            return .attributedType(attrs, type)
        } else if skip("*") {
            let type = try parseNakedType()
            return .addressType(type)
        } else if skip("[") {
            let subtype = try parseNakedType()
            try take("]")
            return .specializedType(.namedType("Array"), [subtype])
        } else if peek("(") {
            let types = try parseMany("(", ",", ")") { try parseNakedType() }
            if skip("->") {
                let result = try parseNakedType()
                return .functionType(types, result)
            } else {
                if types.count == 1 {
                    return types[0]
                } else {
                    return .tupleType(types)
                }
            }
        } else {
            func grow(_ type: Type) throws -> Type {
                if peek("<") {
                    let types = try parseMany("<", ",", ">") { try parseNakedType() }
                    return try grow(.specializedType(type, types))
                } else if skip(".") {
                    let name = try parseTypeName()
                    return try grow(.selectType(type, name))
                } else {
                    return type
                }
            }
            let name = try parseTypeName()
            let base: Type = name != "Self" ? .namedType(name) : .selfType
            return try grow(base)
        }
    }

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#values-and-operands
    func parseOperand() throws -> Operand {
        let valueName = try parseValueName()
        try take(":")
        let type = try parseType()
        return Operand(valueName, type)
    }

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#basic-blocks
    func parseResult() throws -> Result? {
        if peek("%") {
            let valueName = try parseValueName()
            try take("=")
            return Result([valueName])
        } else if peek("(") {
            let valueNames = try parseMany("(", ",", ")") { try parseValueName() }
            try take("=")
            return Result(valueNames)
        } else {
            return nil
        }
    }

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#debug-information
    func parseScopeRef() throws -> Int? {
        guard skip("scope") else { return nil }
        return try parseInt()
    }

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#basic-blocks
    func parseSourceInfo() throws -> SourceInfo? {
        // NB: The SIL docs say that scope refs precede locations, but this is
        //     not true once you look at the compiler outputs or its source code.
        guard skip(",") else { return nil }
        let loc = try parseLoc()
        // NB: No skipping if we failed to parse the location.
        let scopeRef = loc == nil || skip(",") ? try parseScopeRef() : nil
        // We've skipped the comma, so failing to parse any of those two
        // components is an error.
        guard scopeRef != nil || loc != nil else {
            throw parseError("Failed to parse source info")
        }
        return SourceInfo(scopeRef, loc)
    }

    func parseString() throws -> String {
        // TODO(#24): Parse string literals with control characters.
        try take("\"")
        let s = take(while: { $0 != "\"" })
        try take("\"")
        return s
    }

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#tuple
    func parseTupleElements() throws -> TupleElements {
        if peek("$") {
            let type = try parseType()
            let values = try parseMany("(", ",", ")") { try parseValue() }
            return .labeled(type, values)
        } else {
            let operands = try parseMany("(", ",", ")") { try parseOperand() }
            return .unlabeled(operands)
        }
    }

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#sil-types
    func parseType() throws -> Type {
        // NB: Ownership SSA has a surprising convention of printing the
        //     ownership type before the actual type, so we first try to
        //     parse the type attribute.
        if (try? take("$")) == nil {
          let attr = try? parseTypeAttribute()
          // Take the $ for real even if the attribute was not there, because
          // that's the error message we want to show anyway.
          try take("$")
          return .withOwnership(attr!, try parseNakedType())
        }
        return try parseNakedType()
    }

    func parseTypeAttribute() throws -> TypeAttribute {
        guard !skip("@callee_guaranteed") else { return .calleeGuaranteed }
        guard !skip("@convention") else { return .convention(try parseConvention()) }
        guard !skip("@guaranteed") else { return .guaranteed }
        guard !skip("@in_guaranteed") else { return .inGuaranteed }
        // Must appear before "in" to parse correctly.
        guard !skip("@inout") else { return .inout }
        guard !skip("@in") else { return .in }
        guard !skip("@noescape") else { return .noescape }
        guard !skip("@thick") else { return .thick }
        guard !skip("@out") else { return .out }
        guard !skip("@owned") else { return .owned }
        guard !skip("@thin") else { return .thin }
        guard !skip("@yield_once") else { return .yieldOnce }
        guard !skip("@yields") else { return .yields }
        throw parseError("unknown attribute")
    }

    // Type format has been reverse-engineered since it doesn't seem to be mentioned in the spec.
    func parseTypeName() throws -> String {
        let start = position
        // TODO(#14): Make name parsing more thorough.
        let name = take(while: { $0.isLetter || $0.isNumber || $0 == "_" })
        if !name.isEmpty {
            return name
        }
        throw parseError("type name expected", at: start)
    }

    // Type format has been reverse-engineered since it doesn't seem to be mentioned in the spec.
    func parseTypeRequirement() throws -> TypeRequirement {
        let lhs = try parseNakedType()
        if skip(":") {
            let rhs = try parseNakedType()
            return .conformance(lhs, rhs)
        } else if skip("==") {
            let rhs = try parseNakedType()
            return .equality(lhs, rhs)
        } else {
            throw parseError("expected '==' or ':'")
        }
    }

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#values-and-operands
    func parseValue() throws -> String {
        if peek("%") {
            return try parseValueName()
        } else if skip("undef") {
            return "undef"
        } else {
            throw parseError("value expected")
        }
    }

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#values-and-operands
    func parseValueName() throws -> String {
        let start = position
        guard skip("%") else { throw parseError("value expected", at: start) }
        let identifier = try parseIdentifier()
        return "%" + identifier
    }
}
