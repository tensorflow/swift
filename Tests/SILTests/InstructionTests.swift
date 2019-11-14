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

import XCTest
@testable import SIL

let instructionDefs = [
    "%103 = builtin \"ptrtoint_Word\"(%101 : $Builtin.RawPointer) : $Builtin.Word",
    "%139 = builtin \"smul_with_overflow_Int64\"(%136 : $Builtin.Int64, %137 : $Builtin.Int64, %138 : $Builtin.Int1) : $(Builtin.Int64, Builtin.Int1)",
    "cond_fail %141 : $Builtin.Int1, \"\"",
    "%112 = integer_literal $Builtin.Int32, 1",
    "return %1 : $Int",
    "return %280 : $()",
    "retain_value %124 : $TensorShape",
    "release_value %5 : $Tensor<Float>",
    "%180 = struct $Bool (%179 : $Builtin.Int1)",
    "%211 = struct $StaticString (%210 : $Builtin.Word, %209 : $Builtin.Word, %168 : $Builtin.Int8)",
    "%21 = struct_extract %20 : $Int, #Int._value",
    "%64 = tuple_extract %63 : $(Builtin.Int64, Builtin.Int1), 0",
    "alloc_stack $Float",
    "alloc_stack $IndexingIterator<Range<Int>>, var, name \"$inputIndex$generator\"",
    "%79 = alloc_stack $Optional<(Int, Int)>, loc \"Examples/cnn.swift\":16:3, scope 6",
    "apply %10(%1) : $@convention(method) (@guaranteed Array<Float>) -> Int",
    "apply %17<Self>(%1, %2, %16) : $@convention(witness_method: Comparable) <τ_0_0 where τ_0_0 : Comparable> (@in_guaranteed τ_0_0, @in_guaranteed τ_0_0, @thick τ_0_0.Type) -> Bool",
    "apply %8<Int, Int>(%2, %6) : $@convention(thin) <τ_0_0, τ_0_1 where τ_0_0 : Strideable, τ_0_1 : Strideable> (@in_guaranteed τ_0_0, @in_guaranteed τ_0_1) -> ()",
    "%154 = apply %153<Array<Int>, ArraySlice<Int>>(%152, %150, %119) : $@convention(method) <τ_0_0 where τ_0_0 : RangeReplaceableCollection><τ_1_0 where τ_1_0 : Sequence, τ_0_0.Element == τ_1_0.Element> (@inout τ_0_0, @in_guaranteed τ_1_0, @thick τ_0_0.Type) -> (), loc \"example.swift\":22:10, scope 4",
    "%14 = begin_borrow %10 : $Tensor<Float>",
    "%6 = copy_value %0 : $TensorShape, loc \"Examples/cnn.swift\":10:11, scope 3",
    "%54 = copy_value %53 : $Tensor<Float>",
    "destroy_value %10 : $Tensor<Float>",
    "end_borrow %27 : $Tensor<Float>",
    "begin_access [modify] [static] %0 : $*Array<Float>",
    "begin_apply %266(%125, %265) : $@yield_once @convention(method) (Int, @inout Array<Float>) -> @yields @inout Float",
    "br bb9",
    "br label(%0 : $A, %1 : $B)",
    "cond_br %11, bb3, bb2",
    "cond_br %12, label(%0 : $A), label(%1 : $B)",
    "%94 = convert_escape_to_noescape [not_guaranteed] %93 : $@callee_guaranteed () -> Bool to $@noescape @callee_guaranteed () -> Bool",
    "%1 = convert_function %0 : $@convention(thin) () -> Bool to [without_actually_escaping] $@convention(thin) @noescape () -> Bool",
    "copy_addr %1 to [initialization] %33 : $*Self",
    "dealloc_stack %162 : $*IndexingIterator<Range<Int>>",
    "debug_value %1 : $Array<Float>, let, name \"input\", argno 2",
    "debug_value %11 : $Int, let, name \"n\"",
    "debug_value_addr %0 : $*Array<Float>, var, name \"out\", argno 1",
    "debug_value %0 : $TensorShape, let, name \"ar\", argno 1, loc \"Examples/cnn.swift\":9:18, scope 2",
    "end_access %265 : $*Array<Float>",
    "end_access [abort] %42 : $T",
    "end_apply %268",
    "%170 = enum $Padding, #Padding.valid!enumelt",
    "%1 = enum $U, #U.DataCase!enumelt.1, %0 : $T",
    "float_literal $Builtin.FPIEEE32, 0x0",
    "float_literal $Builtin.FPIEEE64, 0x3F800000",
    "function_ref @$s4main11threadCountSiyF : $@convention(thin) () -> Int",
    "function_ref @$ss6stride4from2to2bys8StrideToVyxGx_x0E0QztSxRzlF : $@convention(thin) <τ_0_0 where τ_0_0 : Strideable> (@in_guaranteed τ_0_0, @in_guaranteed τ_0_0, @in_guaranteed τ_0_0.Stride) -> @out StrideTo<τ_0_0>",
    "function_ref @$s4main1CV3fooyyqd___qd_0_tSayqd__GRszSxRd_0_r0_lF : $@convention(method) <τ_0_0><τ_1_0, τ_1_1 where τ_0_0 == Array<τ_1_0>, τ_1_1 : Strideable> (@in_guaranteed τ_1_0, @in_guaranteed τ_1_1, C<Array<τ_1_0>>) -> ()",
    "function_ref @$ss8StrideToV12makeIterators0abD0VyxGyF : $@convention(method) <τ_0_0 where τ_0_0 : Strideable> (@in StrideTo<τ_0_0>) -> @out StrideToIterator<τ_0_0>",
    "%0 = global_addr @$s5small4____Sivp : $*Int",
    "(%5, %6) = destructure_tuple %2 : $(Array<Int>, Builtin.RawPointer)",
    "%42 = index_addr %35 : $*Int, %41 : $Builtin.Word",
    "%7 = pointer_to_address %6 : $Builtin.RawPointer to [strict] $*Int",
    "%7 = pointer_to_address %6 : $Builtin.RawPointer to $*Int",
    "load %117 : $*Optional<Int>",
    "%22 = load [copy] %21 : $*TensorShape",
    "%71 = load [take] %52 : $*Zip2Sequence<Array<Int>, Array<Int>>",
    "%84 = load [trivial] %79 : $*Optional<(Int, Int)>",
    "mark_dependence %11 : $@noescape @callee_guaranteed () -> Bool on %1 : $TensorShape",
    "metatype $@thick Self.Type",
    "metatype $@thin Int.Type",
    "%4 = partial_apply [callee_guaranteed] %2<Scalar>(%3) : $@convention(thin) <τ_0_0 where τ_0_0 : TensorFlowScalar> (@guaranteed Tensor<τ_0_0>) -> Bool",
    "%n = select_enum %0 : $U, case #U.Case1!enumelt: %1, case #U.Case2!enumelt: %2, default %3 : $T",
    "store %88 to %89 : $*StrideTo<Int>",
    "store %88 to [trivial] %112 : $*Int",
    "store %152 to [init] %155 : $*ArraySlice<Int>",
    "string_literal utf8 \"Fatal error\"",
    "strong_release %99 : $@callee_guaranteed () -> @owned String",
    "strong_retain %99 : $@callee_guaranteed () -> @owned String",
    // TODO(#24): Parse string literals with control characters.
    // "string_literal utf8 \"\\n\"",
    "struct_element_addr %235 : $*Float, #Float._value",
    "switch_enum %122 : $Optional<Int>, case #Optional.some!enumelt.1: bb11, case #Optional.none!enumelt: bb18",
    "switch_enum %84 : $Optional<(Int, Int)>, case #Optional.some!enumelt.1: bb5, case #Optional.none!enumelt: bb6, loc \"Examples/cnn.swift\":16:3, scope 6",
    "tuple ()",
    "tuple (%a : $A, %b : $B)",
    // TODO(#23): Parse tuple types with argument labels
    // "tuple $(a:A, b:B) (%a, %b)",
    "%2 = thin_to_thick_function %1 : $@convention(thin) @noescape () -> Bool to $@noescape @callee_guaranteed () -> Bool",
    "unreachable",
    "witness_method $Self, #Comparable.\"<=\"!1 : <Self where Self : Comparable> (Self.Type) -> (Self, Self) -> Bool : $@convention(witness_method: Comparable) <τ_0_0 where τ_0_0 : Comparable> (@in_guaranteed τ_0_0, @in_guaranteed τ_0_0, @thick τ_0_0.Type) -> Bool"
]

// This definition uses a macOS-only trick to dynamically generate test cases.
// That not just doesn't work on Linux but also doesn't compile.
#if os(macOS)
    public final class InstructionTests: XCTestCase {
        // In order to declare this as `let instructionDef: String`, we need to write an appropriate init.
        // In that init, we need to delegate to the superclass init that involves `NSInvocation`.
        // That doesn't seem possible, so we use this hack.
        // error: 'NSInvocation' is unavailable in Swift: NSInvocation and related APIs not available.
        private var instructionDef: String!

        public func testRoundtrip() {
            do {
                let p = SILParser(forString: instructionDef)
                let i = try p.parseInstructionDef()
                XCTAssertEqual(instructionDef, i.description)
            } catch {
                XCTFail(String(describing: error) + "\n" + instructionDef)
            }
        }

        public override class var defaultTestSuite: XCTestSuite {
            let testSuite = XCTestSuite(name: NSStringFromClass(self))
            for instructionDef in instructionDefs {
                for invocation in testInvocations {
                    let testCase = InstructionTests(invocation: invocation)
                    testCase.instructionDef = instructionDef
                    testSuite.addTest(testCase)
                }
            }
            return testSuite
        }
    }
#endif

#if os(Linux)
    public final class InstructionTests: XCTestCase {
    }

    extension InstructionTests {
        public static var allTests = instructionDefs.map { instructionDef in
            (
                "testRoundtrip",
                { (_: InstructionTests) in
                    {
                        do {
                            let p = SILParser(forString: instructionDef)
                            let i = try p.parseInstructionDef()
                            XCTAssertEqual(instructionDef, i.description)
                        } catch {
                            XCTFail(String(describing: error) + "\n" + instructionDef)
                        }
                    }
                }
            )
        }
    }
#endif
