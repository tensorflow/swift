public typealias ValueNameSubstitution = (String) -> String

public protocol CanSubstituteValueNames {
    func substituted(using: ValueNameSubstitution) -> Self
}

extension Block: CanSubstituteValueNames {
    public func substituted(using s: ValueNameSubstitution) -> Block {
        return Block(
            identifier,
            arguments.substituted(using: s),
            operatorDefs.substituted(using: s),
            terminatorDef.substituted(using: s))

    }
}

extension OperatorDef: CanSubstituteValueNames {
    public func substituted(using s: ValueNameSubstitution) -> OperatorDef {
        return OperatorDef(
            result.substituted(using: s),
            `operator`.substituted(using: s),
            sourceInfo)
    }
}

extension TerminatorDef: CanSubstituteValueNames {
    public func substituted(using s: ValueNameSubstitution) -> TerminatorDef {
        return TerminatorDef(terminator.substituted(using: s), sourceInfo)
    }
}

extension InstructionDef: CanSubstituteValueNames {
    public func substituted(using s: ValueNameSubstitution) -> InstructionDef {
        switch self {
        case let .operator(o): return .operator(o.substituted(using: s))
        case let .terminator(t): return .terminator(t.substituted(using: s))
        }
    }
}

extension Operator: CanSubstituteValueNames {
    public func substituted(using s: ValueNameSubstitution) -> Operator {
        switch self {
        case .allocStack(_, _): return self
        case let .apply(nothrow, value, substitutions, arguments, type):
            return .apply(nothrow, s(value), substitutions, arguments.map(s), type)
        case let .beginAccess(access, enforcement, noNestedConflict, builtin, operand):
            return .beginAccess(access, enforcement, noNestedConflict, builtin, operand.substituted(using: s))
        case let .beginApply(nothrow, value, substitutions, arguments, type):
            return .beginApply(nothrow, s(value), substitutions, arguments.map(s), type)
        case let .beginBorrow(operand):
            return .beginBorrow(operand.substituted(using: s))
        case let .builtin(name, operands, type):
            return .builtin(name, operands.substituted(using: s), type)
        case let .condFail(operand, message):
            return .condFail(operand.substituted(using: s), message)
        case let .convertEscapeToNoescape(notGuaranteed, escaped, operand, type):
            return .convertEscapeToNoescape(
                notGuaranteed, escaped, operand.substituted(using: s), type)
        case let .convertFunction(operand, withoutActuallyEscaping, type):
            return .convertFunction(operand.substituted(using: s), withoutActuallyEscaping, type)
        case let .copyAddr(take, value, initialization, operand):
            return .copyAddr(take, s(value), initialization, operand.substituted(using: s))
        case let .copyValue(operand):
            return .copyValue(operand.substituted(using: s))
        case let .deallocStack(operand):
            return .deallocStack(operand.substituted(using: s))
        case let .debugValue(operand, attributes):
            return .debugValue(operand.substituted(using: s), attributes)
        case let .debugValueAddr(operand, attributes):
            return .debugValueAddr(operand.substituted(using: s), attributes)
        case let .destroyValue(operand):
            return .destroyValue(operand.substituted(using: s))
        case let .destructureTuple(operand):
            return .destructureTuple(operand.substituted(using: s))
        case let .endAccess(abort, operand):
            return .endAccess(abort, operand.substituted(using: s))
        case let .endApply(value):
            return .endApply(s(value))
        case let .endBorrow(operand):
            return .endBorrow(operand.substituted(using: s))
        case let .enum(type, declRef, operand):
            return .enum(type, declRef, operand.substituted(using: s))
        case .floatLiteral(_, _): return self
        case .functionRef(_, _): return self
        case .globalAddr(_, _): return self
        case let .indexAddr(addr, index):
            return .indexAddr(addr.substituted(using: s), index.substituted(using: s))
        case .integerLiteral(_, _): return self
        case let .load(ownership, operand):
            return .load(ownership, operand.substituted(using: s))
        case let .markDependence(operand, on):
            return .markDependence(operand.substituted(using: s), on.substituted(using: s))
        case .metatype(_): return self
        case let .partialApply(calleeGuaranteed, onStack, value, substitutions, arguments, type):
            return .partialApply(
                calleeGuaranteed, onStack, s(value), substitutions, arguments.map(s), type)
        case let .pointerToAddress(operand, strict, type):
            return .pointerToAddress(operand.substituted(using: s), strict, type)
        case let .releaseValue(operand):
            return .releaseValue(operand.substituted(using: s))
        case let .retainValue(operand):
            return .retainValue(operand.substituted(using: s))
        case let .store(value, kind, operand):
            return .store(s(value), kind, operand.substituted(using: s))
        case .stringLiteral(_, _): return self
        case let .strongRelease(operand):
            return .strongRelease(operand.substituted(using: s))
        case let .strongRetain(operand):
            return .strongRetain(operand.substituted(using: s))
        case let .struct(type, operands):
            return .struct(type, operands.substituted(using: s))
        case let .structElementAddr(operand, declRef):
            return .structElementAddr(operand.substituted(using: s), declRef)
        case let .structExtract(operand, declRef):
            return .structExtract(operand.substituted(using: s), declRef)
        case let .thinToThickFunction(operand, type):
            return .thinToThickFunction(operand.substituted(using: s), type)
        case let .tuple(elements):
            return .tuple(elements.substituted(using: s))
        case let .tupleExtract(operand, declRef):
            return .tupleExtract(operand.substituted(using: s), declRef)
        case .unknown(_): return self
        case .witnessMethod(_, _, _, _): return self
        }
    }
}

extension Terminator: CanSubstituteValueNames {
    public func substituted(using s: ValueNameSubstitution) -> Terminator {
        switch self {
        case let .br(label, operands):
            return .br(label, operands.substituted(using: s))
        case let .condBr(cond, trueLabel, trueOperands, falseLabel, falseOperands):
            return .condBr(
                s(cond),
                trueLabel, trueOperands.substituted(using: s),
                falseLabel, falseOperands.substituted(using: s))
        case let .return(operand):
            return .return(operand.substituted(using: s))
        case let .switchEnum(operand, cases):
            return .switchEnum(operand.substituted(using: s), cases)
        case .unknown(_): return self
        case .unreachable: return self
        }
    }
}

extension Instruction: CanSubstituteValueNames {
    public func substituted(using s: ValueNameSubstitution) -> Instruction {
        switch self {
        case let .operator(o): return .operator(o.substituted(using: s))
        case let .terminator(t): return .terminator(t.substituted(using: s))
        }
    }
}

extension Argument: CanSubstituteValueNames {
    public func substituted(using s: ValueNameSubstitution) -> Argument {
        return Argument(s(valueName), type)
    }
}

extension Operand: CanSubstituteValueNames {
    public func substituted(using s: ValueNameSubstitution) -> Operand {
        return Operand(s(value), type)
    }
}

extension Result: CanSubstituteValueNames {
    public func substituted(using s: ValueNameSubstitution) -> Result {
        return Result(valueNames.map(s))
    }
}

extension TupleElements: CanSubstituteValueNames {
    public func substituted(using s: ValueNameSubstitution) -> TupleElements {
        switch self {
        case let .labeled(type, values): return .labeled(type, values.map(s))
        case let .unlabeled(operands): return .unlabeled(operands.substituted(using: s))
        }
    }
}

extension Optional: CanSubstituteValueNames where Wrapped: CanSubstituteValueNames {
    public func substituted(using s: ValueNameSubstitution) -> Optional<Wrapped> {
        return map { $0.substituted(using: s) }
    }
}

extension Array: CanSubstituteValueNames where Element: CanSubstituteValueNames {
    public func substituted(using s: ValueNameSubstitution) -> [Element] {
        return map { $0.substituted(using: s) }
    }
}

extension Operator {
    public var operandNames: [String]? {
        if case .unknown(_) = self { return nil }
        var names: [String] = []
        let _ = substituted(using: { names.append($0);return $0 })
        return names
    }
}
