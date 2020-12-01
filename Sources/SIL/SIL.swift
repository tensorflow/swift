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

// https://github.com/apple/swift/blob/main/docs/SIL.rst
public final class Module {
    public var functions: [Function]

    public init(_ functions: [Function]) {
        self.functions = functions
    }

    public static func parse(fromSILPath silPath: String) throws -> Module {
        let parser = try SILParser(forPath: silPath)
        return try parser.parseModule()
    }

    public static func parse(fromString silString: String) throws -> Module {
        let parser = SILParser(forString: silString)
        return try parser.parseModule()
    }
}

// https://github.com/apple/swift/blob/main/docs/SIL.rst#functions
public final class Function {
    public var linkage: Linkage
    public var attributes: [FunctionAttribute]
    public var name: String
    public var type: Type
    public var blocks: [Block]

    public init(
        _ linkage: Linkage, _ attributes: [FunctionAttribute],
        _ name: String, _ type: Type, _ blocks: [Block]
    ) {
        self.linkage = linkage
        self.attributes = attributes
        self.name = name
        self.type = type
        self.blocks = blocks
    }
}

// https://github.com/apple/swift/blob/main/docs/SIL.rst#basic-blocks
public final class Block: Equatable {
    public var identifier: String
    public var arguments: [Argument]
    public var operatorDefs: [OperatorDef]
    public var terminatorDef: TerminatorDef

    public init(_ identifier: String, _ arguments: [Argument], _ operatorDefs: [OperatorDef], _ terminatorDef: TerminatorDef)
    {
        self.identifier = identifier
        self.arguments = arguments
        self.operatorDefs = operatorDefs
        self.terminatorDef = terminatorDef
    }

    public static func ==(_ a: Block, _ b: Block) -> Bool {
        return (a.identifier, a.arguments, a.operatorDefs, a.terminatorDef) == (b.identifier, b.arguments, b.operatorDefs, b.terminatorDef)
    }
}

// https://github.com/apple/swift/blob/main/docs/SIL.rst#basic-blocks
public struct OperatorDef: Equatable {
    public let result: Result?
    public let `operator`: Operator
    public let sourceInfo: SourceInfo?

    public init(_ result: Result?, _ `operator`: Operator, _ sourceInfo: SourceInfo?) {
        self.result = result
        self.operator = `operator`
        self.sourceInfo = sourceInfo
    }
}

// https://github.com/apple/swift/blob/main/docs/SIL.rst#basic-blocks
public struct TerminatorDef: Equatable {
    public let terminator: Terminator
    public let sourceInfo: SourceInfo?

    public init(_ terminator: Terminator, _ sourceInfo: SourceInfo?) {
        self.terminator = terminator
        self.sourceInfo = sourceInfo
    }
}

public enum InstructionDef: Equatable {
    case `operator`(OperatorDef)
    case terminator(TerminatorDef)

    public var instruction: Instruction {
        switch self {
        case let .operator(def): return .operator(def.operator)
        case let .terminator(def): return .terminator(def.terminator)
        }
    }
}


// https://github.com/apple/swift/blob/main/docs/SIL.rst#instruction-set
// https://github.com/apple/swift/blob/main/include/swift/SIL/SILInstruction.h
public enum Operator: Equatable {
    // https://github.com/apple/swift/blob/main/docs/SIL.rst#alloc-stack
    // alloc_stack $Float
    // alloc_stack $IndexingIterator<Range<Int>>, var, name "$inputIndex$generator"
    case allocStack(_ type: Type, _ attributes: [DebugAttribute])

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#apply
    // apply %10(%1) : $@convention(method) (@guaranteed Array<Float>) -> Int
    case apply(
        _ nothrow: Bool, _ value: String,
        _ substitutions: [Type], _ arguments: [String], _ type: Type
    )

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#begin-access
    // begin_access [modify] [static] %0 : $*Array<Float>
    case beginAccess(
        _ access: Access, _ enforcement: Enforcement, _ noNestedConflict: Bool, _ builtin: Bool,
        _ operand: Operand
    )

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#begin-apply
    // begin_apply %266(%125, %265) : $@yield_once @convention(method) (Int, @inout Array<Float>) -> @yields @inout Float
    case beginApply(
        _ nothrow: Bool, _ value: String,
        _ substitutions: [Type], _ arguments: [String], _ type: Type
    )

    // Only used in Ownership SSA
    // begin_borrow %16 : $TensorShape
    case beginBorrow(_ operand: Operand)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#builtin
    // builtin "sadd_with_overflow_Int64"(%4 : $Builtin.Int64, %5 : $Builtin.Int64, %6 : $Builtin.Int1) : $(Builtin.Int64, Builtin.Int1)
    case builtin(_ name: String, _ operands: [Operand], _ type: Type)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#cond-fail
    // cond_fail %9 : $Builtin.Int1, "arithmetic overflow"
    case condFail(_ operand: Operand, _ message: String)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#convert-escape-to-noescape
    // convert_escape_to_noescape [not_guaranteed] %29 : $@callee_guaranteed () -> Bool to $@noescape @callee_guaranteed () -> Bool
    case convertEscapeToNoescape(_ notGuaranteed: Bool, _ escaped: Bool, _ operand: Operand, _ type: Type)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#convert-function
    // convert_function %0 : $@convention(thin) () -> Bool to $@convention(thin) @noescape () -> Bool
    case convertFunction(_ operand: Operand, _ withoutActuallyEscaping: Bool, _ type: Type)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#copy-addr
    // copy_addr %1 to [initialization] %33 : $*Self
    case copyAddr(_ take: Bool, _ value: String, _ initialization: Bool, _ operand: Operand)

    // Only used in Ownership SSA
    // copy_value %53 : $Tensor<Float>
    case copyValue(_ operand: Operand)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#dealloc-stack
    // dealloc_stack %162 : $*IndexingIterator<Range<Int>>
    case deallocStack(_ operand: Operand)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#debug-value
    // debug_value %1 : $Array<Float>, let, name "input", argno 2
    // debug_value %11 : $Int, let, name "n"
    case debugValue(_ operand: Operand, _ attributes: [DebugAttribute])

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#debug-value-addr
    // debug_value_addr %0 : $*Array<Float>, var, name "out", argno 1
    case debugValueAddr(_ operand: Operand, _ attributes: [DebugAttribute])

    // Only used in Ownership SSA
    // destroy_value %30 : $TensorShape
    case destroyValue(_ operand: Operand)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#destructure-tuple
    // destructure_tuple %2 : $(Array<Int>, Builtin.RawPointer)
    case destructureTuple(_ operand: Operand)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#end-access
    // end_access %265 : $*Array<Float>
    // end_access [abort] %42 : $T
    case endAccess(_ abort: Bool, _ operand: Operand)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#end-apply
    // end_apply %268
    case endApply(_ value: String)

    // Only used in Ownership SSA
    // end_borrow %35 : $TensorShape
    case endBorrow(_ operand: Operand)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#enum
    // enum $Padding, #Padding.valid!enumelt
    // enum $U, #U.DataCase!enumelt.1, %0 : $T
    case `enum`(_ type: Type, _ declRef: DeclRef, _ operand: Operand?)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#float-literal
    // float_literal $Builtin.FPIEEE32, 0x0
    // float_literal $Builtin.FPIEEE64, 0x3F800000
    case floatLiteral(_ type: Type, _ value: String)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#function-ref
    // function_ref @$s4main11threadCountSiyF : $@convention(thin) () -> Int
    case functionRef(_ name: String, _ type: Type)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#global-addr
    // global_addr @$s5small4____Sivp : $*Int
    case globalAddr(_ name: String, _ type: Type)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#index-addr
    // index_addr %5 : $*Int, %11 : $Builtin.Word
    case indexAddr(_ addr: Operand, _ index: Operand)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#integer-literal
    // integer_literal $Builtin.Int1, -1
    case integerLiteral(_ type: Type, _ value: Int)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#load
    // load %117 : $*Optional<Int>
    case load(_ kind: LoadOwnership?, _ operand: Operand)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#mark-dependence
    // mark_dependence %11 : $@noescape @callee_guaranteed () -> Bool on %1 : $TensorShape
    case markDependence(_ operand: Operand, _ on: Operand)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#metatype
    // metatype $@thin Int.Type
    case metatype(_ type: Type)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#partial-apply
    // partial_apply [callee_guaranteed] [on_stack] %27(%28) : $@convention(thin) (@guaranteed Int) -> Bool
    case partialApply(
        _ calleeGuaranteed: Bool, _ onStack: Bool, _ value: String,
        _ substitutions: [Type], _ arguments: [String], _ type: Type
    )

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#pointer-to-address
    // pointer_to_address %4 : $Builtin.RawPointer to [strict] $*Int
    case pointerToAddress(_ operand: Operand, _ strict: Bool, _ type: Type)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#release-value
    // release_value %21 : $TensorShape
    case releaseValue(_ operand: Operand)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#retain-value
    // retain_value %124 : $TensorShape
    case retainValue(_ operand: Operand)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#select-enum
    // %n = select_enum %0 : $U, case #U.Case1!enumelt: %1, case #U.Case2!enumelt: %2, default %3 : $T
    case selectEnum(_ operand: Operand, _ cases: [Case], _ type: Type)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#store
    // store %88 to %89 : $*StrideTo<Int>
    case store(_ value: String, _ kind: StoreOwnership?, _ operand: Operand)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#string-literal
    // string_literal utf8 "Fatal error"
    case stringLiteral(_ encoding: Encoding, _ value: String)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#strong-release
    // strong_release %99 : $@callee_guaranteed () -> @owned String
    case strongRelease(_ operand: Operand)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#strong-retain
    // strong_retain %22 : $@callee_guaranteed () -> @owned String
    case strongRetain(_ operand: Operand)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#struct
    // struct $Int (%8 : $Builtin.Int64)
    case `struct`(_ type: Type, _ operands: [Operand])

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#struct-element-addr
    // struct_element_addr %235 : $*Float, #Float._value
    case structElementAddr(_ operand: Operand, _ declRef: DeclRef)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#struct-extract
    // struct_extract %0 : $Int, #Int._value
    case structExtract(_ operand: Operand, _ declRef: DeclRef)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#thin-to-thick-function
    // %2 = thin_to_thick_function %1 : $@convention(thin) @noescape () -> Bool to $@noescape @callee_guaranteed () -> Bool
    case thinToThickFunction(_ operand: Operand, _ type: Type)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#tuple
    // tuple (%a : $A, %b : $B, ...)
    // tuple $(a:A, b:B, ...) (%a, %b, ...)
    case tuple(_ elements: TupleElements)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#tuple-extract
    // tuple_extract %7 : $(Builtin.Int64, Builtin.Int1), 0
    case tupleExtract(_ operand: Operand, _ declRef: Int)

    // Used as a temporary workaround in parser
    case unknown(_ name: String)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#witness-method
    // witness_method $Self, #Comparable."<="!1 : <Self where Self : Comparable> (Self.Type) -> (Self, Self) -> Bool : $@convention(witness_method: Comparable) <τ_0_0 where τ_0_0 : Comparable> (@in_guaranteed τ_0_0, @in_guaranteed τ_0_0, @thick τ_0_0.Type) -> Bool
    // TODO(#28): Figure out witness_method.
    case witnessMethod(_ archeType: Type, _ declRef: DeclRef, _ declType: Type, _ type: Type)
}

// https://github.com/apple/swift/blob/main/docs/SIL.rst#terminators
public enum Terminator: Equatable {
    // https://github.com/apple/swift/blob/main/docs/SIL.rst#br
    // br bb9
    // br label (%0 : $A, %1 : $B)
    case br(_ label: String, _ operands: [Operand])

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#cond-br
    // cond_br %11, bb3, bb2
    // cond_br %12, label (%0 : $A), label (%1 : $B)
    // TODO(#25): Figure out cond_br.
    case condBr(
        _ cond: String,
        _ trueLabel: String, _ trueOperands: [Operand],
        _ falseLabel: String, _ falseOperands: [Operand]
    )

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#return
    // return %11 : $Int
    case `return`(_ operand: Operand)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#switch-enum
    // switch_enum %122 : $Optional<Int>, case #Optional.some!enumelt.1: bb11, case #Optional.none!enumelt: bb18
    case switchEnum(_ operand: Operand, _ cases: [Case])

    // Used in case of parse failures and unsupported terminators
    case unknown(_ name: String)

    // https://github.com/apple/swift/blob/main/docs/SIL.rst#unreachable
    // unreachable
    case unreachable
}

public enum Instruction: Equatable {
    case `operator`(Operator)
    case terminator(Terminator)
}

// MARK: Auxiliary data structures

// https://github.com/apple/swift/blob/main/docs/SIL.rst#begin-access
public enum Access: Equatable {
    case `deinit`
    case `init`
    case modify
    case read
}

// https://github.com/apple/swift/blob/main/docs/SIL.rst#basic-blocks
public struct Argument: Equatable {
    public let valueName: String
    public let type: Type

    public init(_ valueName: String, _ type: Type) {
        self.valueName = valueName
        self.type = type
    }
}

// https://github.com/apple/swift/blob/main/docs/SIL.rst#switch-enum
public enum Case: Equatable {
    case `case`(_ declRef: DeclRef, _ result: String)
    case `default`(_ result: String)
}

// https://github.com/apple/swift/blob/main/docs/SIL.rst#calling-convention
public enum Convention: Equatable {
    case c
    case method
    case thin
    case witnessMethod(_ type: Type)
}

// https://github.com/apple/swift/blob/main/docs/SIL.rst#debug-value
public enum DebugAttribute: Equatable {
    case argno(_ index: Int)
    case name(_ name: String)
    case `let`
    case `var`
}

// https://github.com/apple/swift/blob/main/include/swift/SIL/SILDeclRef.h
// https://github.com/apple/swift/blob/main/docs/SIL.rst#declaration-references
public enum DeclKind: Equatable {
    case allocator
    case deallocator
    case destroyer
    case enumElement
    case getter
    case globalAccessor
    case initializer
    case ivarDestroyer
    case ivarInitializer
    case setter
}

// https://github.com/apple/swift/blob/main/include/swift/SIL/SILDeclRef.h
// https://github.com/apple/swift/blob/main/docs/SIL.rst#declaration-references
public struct DeclRef: Equatable {
    public let name: [String]
    public let kind: DeclKind?
    public let level: Int?

    public init(_ name: [String], _ kind: DeclKind?, _ level: Int?) {
        self.name = name
        self.kind = kind
        self.level = level
    }
}

// https://github.com/apple/swift/blob/main/docs/SIL.rst#string-literal
public enum Encoding: Equatable {
    case objcSelector
    case utf8
    case utf16
}

// https://github.com/apple/swift/blob/main/docs/SIL.rst#begin-access
public enum Enforcement: Equatable {
    case dynamic
    case `static`
    case unknown
    case unsafe
}

// Reverse-engineered from -emit-sil
public enum FunctionAttribute: Equatable {
    case alwaysInline
    case differentiable(_ spec: String)
    case dynamicallyReplacable
    case noInline
    case readonly
    case semantics(_ value: String)
    case serialized
    case thunk
    case transparent
    case noncanonical(NoncanonicalFunctionAttribute)
}

public enum NoncanonicalFunctionAttribute: Equatable {
    case ownershipSSA
}

// https://github.com/apple/swift/blob/main/docs/SIL.rst#linkage
public enum Linkage: Equatable {
    case hidden
    case hiddenExternal
    case `private`
    case privateExternal
    case `public`
    case publicExternal
    case publicNonABI
    case shared
    case sharedExternal
}

// https://github.com/apple/swift/blob/main/docs/SIL.rst#debug-information
public struct Loc: Equatable {
    public let path: String
    public let line: Int
    public let column: Int

    public init(_ path: String, _ line: Int, _ column: Int) {
        self.path = path
        self.line = line
        self.column = column
    }
}

// https://github.com/apple/swift/blob/main/docs/SIL.rst#values-and-operands
public struct Operand: Equatable {
    public let value: String
    public let type: Type

    public init(_ value: String, _ type: Type) {
        self.value = value
        self.type = type
    }
}

// https://github.com/apple/swift/blob/main/docs/SIL.rst#basic-blocks
public struct Result: Equatable {
    public let valueNames: [String]

    public init(_ valueNames: [String]) {
        self.valueNames = valueNames
    }
}

// https://github.com/apple/swift/blob/main/docs/SIL.rst#basic-blocks
public struct SourceInfo: Equatable {
    public let scopeRef: Int?
    public let loc: Loc?

    public init(_ scopeRef: Int?, _ loc: Loc?) {
        self.scopeRef = scopeRef
        self.loc = loc
    }
}

// https://github.com/apple/swift/blob/main/docs/SIL.rst#tuple
public enum TupleElements: Equatable {
    case labeled(_ type: Type, _ values: [String])
    case unlabeled(_ operands: [Operand])
}

// Reverse-engineered from -emit-sil
public indirect enum Type: Equatable {
    case addressType(_ type: Type)
    case attributedType(_ attributes: [TypeAttribute], _ type: Type)
    case coroutineTokenType
    case functionType(_ parameters: [Type], _ result: Type)
    case genericType(_ parameters: [String], _ requirements: [TypeRequirement], _ type: Type)
    case namedType(_ name: String)
    case selectType(_ type: Type, _ name: String)
    case selfType
    case specializedType(_ type: Type, _ arguments: [Type])
    case tupleType(_ parameters: [Type])
    case withOwnership(_ attribute: TypeAttribute, _ type: Type) // Only used in ownership SSA

    public static func parse(fromString silString: String) throws -> Type {
        let parser = SILParser(forString: silString)
        return try parser.parseType()
    }
}

// https://github.com/apple/swift/blob/main/docs/SIL.rst#properties-of-types
public enum TypeAttribute: Equatable {
    case calleeGuaranteed
    case convention(_ convention: Convention)
    case guaranteed
    case inGuaranteed
    case `in`
    case `inout`
    case noescape
    case out
    case owned
    case thick
    case thin
    case yieldOnce
    case yields
}

// Reverse-engineered from -emit-sil
public enum TypeRequirement: Equatable {
    case conformance(_ lhs: Type, _ rhs: Type)
    case equality(_ lhs: Type, _ rhs: Type)
}

// Reverse-engineered from -emit-silgen
public enum LoadOwnership: Equatable {
    case copy
    case take
    case trivial
}

// Reverse-engineered from -emit-silgen
public enum StoreOwnership: Equatable {
    case `init`
    case trivial
}
