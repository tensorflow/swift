public typealias ValueNameSubstitution = (String) -> String

public protocol AlphaConvertible {
    func alphaConverted(using: ValueNameSubstitution) -> Self
}

extension Block: AlphaConvertible {
    public func alphaConverted(using s: ValueNameSubstitution) -> Block {
        return Block(
            identifier,
            arguments.alphaConverted(using: s),
            operatorDefs.alphaConverted(using: s),
            terminatorDef.alphaConverted(using: s))

    }
}

extension OperatorDef: AlphaConvertible {
    public func alphaConverted(using s: ValueNameSubstitution) -> OperatorDef {
        return OperatorDef(
            result.alphaConverted(using: s),
            `operator`.alphaConverted(using: s),
            sourceInfo)
    }
}

extension TerminatorDef: AlphaConvertible {
    public func alphaConverted(using s: ValueNameSubstitution) -> TerminatorDef {
        return TerminatorDef(terminator.alphaConverted(using: s), sourceInfo)
    }
}

extension InstructionDef: AlphaConvertible {
    public func alphaConverted(using s: ValueNameSubstitution) -> InstructionDef {
        switch self {
        case let .operator(o): return .operator(o.alphaConverted(using: s))
        case let .terminator(t): return .terminator(t.alphaConverted(using: s))
        }
    }
}

extension Operator: AlphaConvertible {
    public func alphaConverted(using s: ValueNameSubstitution) -> Operator {
        switch self {
        case .allocStack(_, _): return self
        case let .apply(nothrow, value, substitutions, arguments, type):
            return .apply(nothrow, s(value), substitutions, arguments.map(s), type)
        case let .beginAccess(access, enforcement, noNestedConflict, builtin, operand):
            return .beginAccess(access, enforcement, noNestedConflict, builtin, operand.alphaConverted(using: s))
        case let .beginApply(nothrow, value, substitutions, arguments, type):
            return .beginApply(nothrow, s(value), substitutions, arguments.map(s), type)
        case let .beginBorrow(operand):
            return .beginBorrow(operand.alphaConverted(using: s))
        case let .builtin(name, operands, type):
            return .builtin(name, operands.alphaConverted(using: s), type)
        case let .condFail(operand, message):
            return .condFail(operand.alphaConverted(using: s), message)
        case let .convertEscapeToNoescape(notGuaranteed, escaped, operand, type):
            return .convertEscapeToNoescape(
                notGuaranteed, escaped, operand.alphaConverted(using: s), type)
        case let .convertFunction(operand, withoutActuallyEscaping, type):
            return .convertFunction(operand.alphaConverted(using: s), withoutActuallyEscaping, type)
        case let .copyAddr(take, value, initialization, operand):
            return .copyAddr(take, s(value), initialization, operand.alphaConverted(using: s))
        case let .copyValue(operand):
            return .copyValue(operand.alphaConverted(using: s))
        case let .deallocStack(operand):
            return .deallocStack(operand.alphaConverted(using: s))
        case let .debugValue(operand, attributes):
            return .debugValue(operand.alphaConverted(using: s), attributes)
        case let .debugValueAddr(operand, attributes):
            return .debugValueAddr(operand.alphaConverted(using: s), attributes)
        case let .destroyValue(operand):
            return .destroyValue(operand.alphaConverted(using: s))
        case let .destructureTuple(operand):
            return .destructureTuple(operand.alphaConverted(using: s))
        case let .endAccess(abort, operand):
            return .endAccess(abort, operand.alphaConverted(using: s))
        case let .endApply(value):
            return .endApply(s(value))
        case let .endBorrow(operand):
            return .endBorrow(operand.alphaConverted(using: s))
        case let .enum(type, declRef, operand):
            return .enum(type, declRef, operand.alphaConverted(using: s))
        case .floatLiteral(_, _): return self
        case .functionRef(_, _): return self
        case .globalAddr(_, _): return self
        case let .indexAddr(addr, index):
            return .indexAddr(addr.alphaConverted(using: s), index.alphaConverted(using: s))
        case .integerLiteral(_, _): return self
        case let .load(ownership, operand):
            return .load(ownership, operand.alphaConverted(using: s))
        case let .markDependence(operand, on):
            return .markDependence(operand.alphaConverted(using: s), on.alphaConverted(using: s))
        case .metatype(_): return self
        case let .partialApply(calleeGuaranteed, onStack, value, substitutions, arguments, type):
            return .partialApply(
                calleeGuaranteed, onStack, s(value), substitutions, arguments.map(s), type)
        case let .pointerToAddress(operand, strict, type):
            return .pointerToAddress(operand.alphaConverted(using: s), strict, type)
        case let .releaseValue(operand):
            return .releaseValue(operand.alphaConverted(using: s))
        case let .retainValue(operand):
            return .retainValue(operand.alphaConverted(using: s))
        case let .store(value, kind, operand):
            return .store(s(value), kind, operand.alphaConverted(using: s))
        case .stringLiteral(_, _): return self
        case let .strongRelease(operand):
            return .strongRelease(operand.alphaConverted(using: s))
        case let .strongRetain(operand):
            return .strongRetain(operand.alphaConverted(using: s))
        case let .struct(type, operands):
            return .struct(type, operands.alphaConverted(using: s))
        case let .structElementAddr(operand, declRef):
            return .structElementAddr(operand.alphaConverted(using: s), declRef)
        case let .structExtract(operand, declRef):
            return .structExtract(operand.alphaConverted(using: s), declRef)
        case let .thinToThickFunction(operand, type):
            return .thinToThickFunction(operand.alphaConverted(using: s), type)
        case let .tuple(elements):
            return .tuple(elements.alphaConverted(using: s))
        case let .tupleExtract(operand, declRef):
            return .tupleExtract(operand.alphaConverted(using: s), declRef)
        case .unknown(_): return self
        case .witnessMethod(_, _, _, _): return self
        }
    }
}

extension Terminator: AlphaConvertible {
    public func alphaConverted(using s: ValueNameSubstitution) -> Terminator {
        switch self {
        case let .br(label, operands):
            return .br(label, operands.alphaConverted(using: s))
        case let .condBr(cond, trueLabel, trueOperands, falseLabel, falseOperands):
            return .condBr(
                s(cond),
                trueLabel, trueOperands.alphaConverted(using: s),
                falseLabel, falseOperands.alphaConverted(using: s))
        case let .return(operand):
            return .return(operand.alphaConverted(using: s))
        case let .switchEnum(operand, cases):
            return .switchEnum(operand.alphaConverted(using: s), cases)
        case .unknown(_): return self
        case .unreachable: return self
        }
    }
}

extension Instruction: AlphaConvertible {
    public func alphaConverted(using s: ValueNameSubstitution) -> Instruction {
        switch self {
        case let .operator(o): return .operator(o.alphaConverted(using: s))
        case let .terminator(t): return .terminator(t.alphaConverted(using: s))
        }
    }
}

extension Argument: AlphaConvertible {
    public func alphaConverted(using s: ValueNameSubstitution) -> Argument {
        return Argument(s(valueName), type)
    }
}

extension Operand: AlphaConvertible {
    public func alphaConverted(using s: ValueNameSubstitution) -> Operand {
        return Operand(s(value), type)
    }
}

extension Result: AlphaConvertible {
    public func alphaConverted(using s: ValueNameSubstitution) -> Result {
        return Result(valueNames.map(s))
    }
}

extension TupleElements: AlphaConvertible {
    public func alphaConverted(using s: ValueNameSubstitution) -> TupleElements {
        switch self {
        case let .labeled(type, values): return .labeled(type, values.map(s))
        case let .unlabeled(operands): return .unlabeled(operands.alphaConverted(using: s))
        }
    }
}

extension Optional: AlphaConvertible where Wrapped: AlphaConvertible {
    public func alphaConverted(using s: ValueNameSubstitution) -> Optional<Wrapped> {
        return map { $0.alphaConverted(using: s) }
    }
}

extension Array: AlphaConvertible where Element: AlphaConvertible {
    public func alphaConverted(using s: ValueNameSubstitution) -> [Element] {
        return map { $0.alphaConverted(using: s) }
    }
}

extension Operator {
    public var operandNames: [String]? {
        if case .unknown(_) = self { return nil }
        var names: [String] = []
        let _ = alphaConverted(using: { names.append($0);return $0 })
        return names
    }
}
