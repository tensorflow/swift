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

public final class BitcodeTests: XCTestCase {
    private func testLoadingSIB() {
        do {
            let topBlock = try loadSIBBitcode(fromPath: "Tests/SILTests/Resources/AddFloat.sib")
            XCTAssertEqual(topBlock.subblocks.count, 1)
            let moduleBlock = topBlock.subblocks[0]
            XCTAssertEqual(moduleBlock.subblocks.count, 7)
            let silBlock = moduleBlock.subblocks[2]
            let p = BitcodePrinter()
            p.print(silBlock)
            XCTAssertEqual(
                p.description,
                """
                <SIL_BLOCK NumWords=142 BlockCodeSize=6>
                  <SIL_FUNCTION op0=0 op1=0 op2=0 op3=0 op4=0 op5=0 op6=0 op7=0 op8=4 op9=0 op10=0 op11=0 op12=0 op13=1 op14=0 op15=0 op16=0/>
                  <SIL_BASIC_BLOCK op0=2 op1=768 op2=2 op3=3 op4=768 op5=3/>
                  <SIL_ONE_OPERAND op0=20 op1=0 op2=4 op3=0 op4=6/>
                  <SIL_ONE_TYPE_VALUES op0=87 op1=2 op2=0 op3=4 op4=0 op5=4/>
                  <SIL_ONE_OPERAND op0=113 op1=0 op2=2 op3=0 op4=5/>
                  <SIL_FUNCTION op0=2 op1=0 op2=0 op3=0 op4=0 op5=0 op6=0 op7=0 op8=4 op9=0 op10=0 op11=0 op12=0 op13=5 op14=0 op15=0 op16=0/>
                  <SIL_BASIC_BLOCK op0=6 op1=768 op2=2/>
                  <SIL_ONE_OPERAND op0=21 op1=0 op2=7 op3=0 op4=7/>
                  <SIL_ONE_VALUE_ONE_OPERAND op0=88 op1=0 op2=1 op3=6 op4=0 op5=2/>
                  <SIL_INST_APPLY op0=2 op1=0 op2=7 op3=0 op4=8 op5=4 op6=7 op7=0 op8=3 op9=7 op10=0/>
                  <SIL_ONE_TYPE_VALUES op0=87 op1=6 op2=0 op3=7 op4=0 op5=5/>
                  <SIL_ONE_OPERAND op0=113 op1=0 op2=6 op3=0 op4=6/>
                </SIL_BLOCK>
                """
            )
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }
}

extension BitcodeTests {
    public static let allTests: [(String, (BitcodeTests) -> () -> Void)] = [
        // TODO(TF-774): Disabling the test since it's not on the critical path at the moment.
        // ("testLoadingSIB", testLoadingSIB),
    ]
}
