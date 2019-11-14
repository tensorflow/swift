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

import Foundation
import XCTest
@testable import SIL

func parseDef(_ source: String) -> InstructionDef? {
    do {
        let p = SILParser(forString: source)
        return try p.parseInstructionDef()
    } catch {
        XCTFail(String(describing: error) + "\n" + source)
        return nil
    }
}

public final class SILAnalysisTests: XCTestCase {
    lazy var parsedInstructionDefs: [InstructionDef] = instructionDefs.compactMap(parseDef)

    public func testAlphaConverted() {
        for def in parsedInstructionDefs {
            checkValueNames(def.alphaConverted(using: { _ in "%TEST_NAME" }))
        }
    }

    // Only allows %TEST_NAME as the value name
    func checkValueNames(_ i: InstructionDef) {
        var readingValueName = false
        var name = ""
        for c in i.description {
            if c == "%" {
                name = "%"
                assert(!readingValueName)
                readingValueName = true
                continue
            }
            guard readingValueName else { continue }
            if c.isLetter || c.isNumber || c == "_" {
                name.append(c)
            } else {
                XCTAssertEqual(name, "%TEST_NAME")
                readingValueName = false
            }
        }
    }

    public func testOperandsSeeAllValueNames() {
        for def in parsedInstructionDefs {
            var valueNames: [String] = []
            let _ = def.instruction.alphaConverted(using: { valueNames.append($0);return $0 })
            guard let operands = def.instruction.operands else {
                XCTFail("Failed to retrieve operands of \(def)")
                continue
            }
            XCTAssertEqual(operands.map { $0.value }, valueNames)
        }
    }

    public func testOperandsOfApplyInstructions() {
        func verifyApply(_ defSource: String, _ expectedOperands: [Operand]) {
            guard let partialApplyDef = parseDef(defSource) else {
                return XCTFail("Failed to parse the partial_apply case")
            }
            let partialApply = partialApplyDef.instruction
            guard let operands = partialApply.operands else {
                return XCTFail("Failed to get a correct list of operands")
            }
            XCTAssertEqual(Array(operands[1...]), expectedOperands)
        }
        verifyApply(
            "apply %8<Int, Int>(%2, %6) : $@convention(thin) <τ_0_0, τ_0_1 where τ_0_0 : Strideable, τ_0_1 : Strideable> (@in_guaranteed τ_0_0, @in_guaranteed τ_0_1) -> ()",
            [
                Operand("%2", .attributedType([.inGuaranteed], .namedType("Int"))),
                Operand("%6", .attributedType([.inGuaranteed], .namedType("Int"))),
            ]
        )
        verifyApply(
            "begin_apply %266(%125, %265) : $@yield_once @convention(method) (Int, @inout Array<Float>) -> @yields @inout Float",
            [
                Operand("%125", .namedType("Int")),
                Operand(
                    "%265",
                    .attributedType(
                        [.inout], .specializedType(.namedType("Array"), [.namedType("Float")]))),
            ]
        )
        verifyApply(
            "%4 = partial_apply [callee_guaranteed] %2<Scalar>(%3) : $@convention(thin) <τ_0_0 where τ_0_0 : TensorFlowScalar> (@guaranteed Tensor<τ_0_0>) -> Bool",
            [
                Operand(
                    "%3",
                    .attributedType(
                        [.guaranteed],
                        .specializedType(.namedType("Tensor"), [.namedType("Scalar")])))
            ]
        )
    }
}

extension SILAnalysisTests {
    public static let allTests = [
        ("testAlphaConverted", testAlphaConverted),
        ("testOperandsSeeAllValueNames", testOperandsSeeAllValueNames),
        ("testOperandsOfApplyInstructions", testOperandsOfApplyInstructions),
    ]
}
