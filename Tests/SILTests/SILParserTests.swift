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

public final class SILParserTests: XCTestCase {
    public func testArrayDesugar() {
        let instr = "%149 = apply %148<[Int], PartialRangeFrom<Int>>(%143, %146, %144) : $@convention(method) <τ_0_0 where τ_0_0 : MutableCollection><τ_1_0 where τ_1_0 : RangeExpression, τ_0_0.Index == τ_1_0.Bound> (@in_guaranteed τ_1_0, @in_guaranteed τ_0_0) -> @out τ_0_0.SubSequence"
        let parser = SILParser(forString: instr)
        do {
            guard case let .operator(def) = try parser.parseInstructionDef() else {
                return XCTFail("Expected the result to be a non-terminating instruction")
            }
            XCTAssertEqual(def.description, instr.replacingOccurrences(of: "[Int]", with: "Array<Int>"))
        } catch {
            XCTFail("Failed to parse the instruction def: \(error)")
        }
    }

    public func testInstructionParseError() {
        let instr = "%122 = apply garbage..."
        let parser = SILParser(forString: instr)
        do {
            guard case let .operator(def) = try parser.parseInstructionDef() else {
                return XCTFail("Expected the result to be a non-terminating instruction")
            }
            guard case .unknown("apply") = def.operator else {
                return XCTFail("Expected .unknown(apply), got \(def.operator)")
            }
        } catch {
            XCTFail("Failed to parse the instruction def: \(error)")
        }
    }
}

extension SILParserTests {
    public static let allTests = [
        ("testArrayDesugar", testArrayDesugar),
    ]
}

