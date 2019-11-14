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
            return .beginAccess(
                access, enforcement, noNestedConflict, builtin, operand.alphaConverted(using: s))
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
        case let .selectEnum(operand, cases, type):
            return .selectEnum(operand.alphaConverted(using: s), cases.alphaConverted(using: s), type)
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

extension Case: AlphaConvertible {
    public func alphaConverted(using s: ValueNameSubstitution) -> Case {
        switch self {
        case let .case(declRef, result): return .case(declRef, s(result))
        case let .default(result): return .default(s(result))
        }
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

extension Type {
    public func substituted(using s: (String) -> Type) -> Type {
        switch self {
        case let .addressType(subtype):
            return .addressType(subtype.substituted(using: s))
        case let .attributedType(attributes, subtype):
            return .attributedType(attributes, subtype.substituted(using: s))
        case .coroutineTokenType:
            return .coroutineTokenType
        case let .functionType(parameters, result):
            return .functionType(
                parameters.map { $0.substituted(using: s) }, result.substituted(using: s))
        case let .genericType(parameters, requirements, subtype):
            return .genericType(
                parameters,
                requirements,
                subtype.substituted(using: { parameters.contains($0) ? .namedType($0) : s($0) }))
        case let .namedType(name):
            return s(name)
        case let .selectType(subtype, name):
            return .selectType(subtype.substituted(using: s), name)
        case .selfType:
            return .selfType
        case let .specializedType(genericType, arguments):
            return .specializedType(
                genericType.substituted(using: s), arguments.map { $0.substituted(using: s) })
        case let .tupleType(elementTypes):
            return .tupleType(elementTypes.map { $0.substituted(using: s) })
        case let .withOwnership(attribute, subtype):
            return .withOwnership(attribute, subtype.substituted(using: s))
        }
    }

    public func specialized(to arguments: [Type]) -> Type {
        switch self {
        case let .addressType(subtype):
            return .addressType(subtype.specialized(to: arguments))
        case let .attributedType(attributes, subtype):
            return .attributedType(attributes, subtype.specialized(to: arguments))
        case let .genericType(startParameters, _, startSubtype):
            var parameters = startParameters
            var subtype = startSubtype
            while case let .genericType(moreParameters, _, deeperSubtype) = subtype {
                parameters += moreParameters
                subtype = deeperSubtype
            }
            guard parameters.count == arguments.count else {
                fatalError(
                    "Specializing a generic type with \(parameters.count) parameters using \(arguments.count) arguments"
                )
            }
            let valuation = [String: Type](
                zip(parameters, arguments),
                uniquingKeysWith: { _, _ in fatalError("Duplicate parameter names in generic type") })
            return subtype.substituted(using: { valuation[$0] ?? .namedType($0) })
        case let .selectType(subtype, name):
            return .selectType(subtype.specialized(to: arguments), name)
        case let .withOwnership(attribute, subtype):
            return .withOwnership(attribute, subtype.specialized(to: arguments))
        case .coroutineTokenType: fallthrough
        case .functionType(_, _): fallthrough
        case .namedType(_): fallthrough
        case .selfType: fallthrough
        case .specializedType(_, _): fallthrough
        case .tupleType(_):
            fatalError("Specializing a type that is not generic")
        }
    }

    public var functionSignature: (arguments: [Type], result: Type) {
        switch self {
        case let .attributedType(_, subtype):
            return subtype.functionSignature
        case let .functionType(arguments, result):
            return (arguments, result)
        case let .genericType(_, _, subtype):
            return subtype.functionSignature
        case let .withOwnership(_, subtype):
            return subtype.functionSignature
        case .addressType(_): fallthrough
        case .coroutineTokenType: fallthrough
        case .namedType(_): fallthrough
        case .selectType(_, _): fallthrough
        case .selfType: fallthrough
        case .specializedType(_, _): fallthrough
        case .tupleType(_):
            fatalError("Expected a function type")
        }
    }
}

extension Operator {
    public var operands: [Operand]? {
        switch self {
        case .allocStack(_, _): return []
        case let .apply(_, function, substitutions, arguments, type): fallthrough
        case let .beginApply(_, function, substitutions, arguments, type):
            let specializedType = substitutions.isEmpty ? type : type.specialized(to: substitutions)
            let (arguments:argumentTypes, result:_) = specializedType.functionSignature
            return [Operand(function, type)] + zip(arguments, argumentTypes).map {
                Operand($0.0, $0.1)
            }
        case let .beginAccess(_, _, _, _, operand): return [operand]
        case let .beginBorrow(operand): return [operand]
        case let .builtin(_, operands, _): return operands
        case let .condFail(operand, _): return [operand]
        case let .convertEscapeToNoescape(_, _, operand, _): return [operand]
        case let .convertFunction(operand, _, _): return [operand]
        case let .copyAddr(_, value, _, operand): return [Operand(value, operand.type), operand]
        case let .copyValue(operand): return [operand]
        case let .deallocStack(operand): return [operand]
        case let .debugValue(operand, _): return [operand]
        case let .debugValueAddr(operand, _): return [operand]
        case let .destroyValue(operand): return [operand]
        case let .destructureTuple(operand): return [operand]
        case let .endAccess(_, operand): return [operand]
        case let .endApply(value): return [Operand(value, .coroutineTokenType)]
        case let .endBorrow(operand): return [operand]
        case let .enum(_, _, maybeOperand): return maybeOperand.map { [$0] } ?? []
        case .floatLiteral(_, _): return []
        case .functionRef(_, _): return []
        case .globalAddr(_, _): return []
        case let .indexAddr(addr, index): return [addr, index]
        case .integerLiteral(_, _): return []
        case let .load(_, operand): return [operand]
        case let .markDependence(operand, on): return [operand, on]
        case .metatype(_): return []
        case let .partialApply(_, _, function, substitutions, arguments, type):
            let specializedType = substitutions.isEmpty ? type : type.specialized(to: substitutions)
            let (arguments:allArgumentTypes, result:_) = specializedType.functionSignature
            let argumentTypes = allArgumentTypes.suffix(arguments.count)
            assert(arguments.count == argumentTypes.count)
            return [Operand(function, type)] + zip(arguments, argumentTypes).map {
                Operand($0.0, $0.1)
            }
        case let .pointerToAddress(operand, _, _): return [operand]
        case let .releaseValue(operand): return [operand]
        case let .retainValue(operand): return [operand]
        case let .selectEnum(operand, cases, type):
            return [operand] + cases.map {
                switch $0 {
                case let .case(_, value): return Operand(value, type)
                case let .default(value): return Operand(value, type)
                }
            }
        case let .store(value, _, operand):
            guard case let .addressType(valueType) = operand.type else {
                fatalError("Store to a non-address type operand")
            }
            return [Operand(value, valueType), operand]
        case .stringLiteral(_, _): return []
        case let .strongRelease(operand): return [operand]
        case let .strongRetain(operand): return [operand]
        case let .struct(_, operands): return operands
        case let .structElementAddr(operand, _): return [operand]
        case let .structExtract(operand, _): return [operand]
        case let .thinToThickFunction(operand, _): return [operand]
        case let .tuple(elements):
            switch elements {
            case let .unlabeled(operands): return operands
            case let .labeled(tupleType, operands):
                guard case let .tupleType(elementTypes) = tupleType else {
                    fatalError("Tuple of non-tuple type")
                }
                return zip(operands, elementTypes).map { Operand($0.0, $0.1) }
            }
        case let .tupleExtract(operand, _): return [operand]
        case .unknown(_): return nil
        case .witnessMethod(_, _, _, _): return []
        }
    }
}

extension Terminator {
    public var operands: [Operand]? {
        switch self {
        case let .br(_, operands): return operands
        case let .condBr(cond, _, trueOperands, _, falseOperands):
            return [Operand(cond, .selectType(.namedType("Builtin"), "Int1"))] + trueOperands
                + falseOperands
        case let .return(operand): return [operand]
        case let .switchEnum(operand, _): return [operand]
        case .unknown(_): return nil
        case .unreachable: return []
        }
    }
}

extension Instruction {
    public var operands: [Operand]? {
        switch self {
        case let .operator(op): return op.operands
        case let .terminator(t): return t.operands
        }
    }
}
