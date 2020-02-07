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

public final class PrinterTests: XCTestCase {
    public func testIndent() {
        let p = Printer()
        p.print("line")
        p.indent()
        p.print(" #1\n")
        p.print("line #2\n")
        p.print("line #3\n\nline #5\n")
        p.print("\n")
        p.print("line #7")
        p.print("\n\n")
        p.unindent()
        p.print("line #9")
        XCTAssertEqual(
            p.description,
            """
      line #1
        line #2
        line #3

        line #5

        line #7

      line #9
      """
        )
    }
}

extension PrinterTests {
    public static let allTests = [
        ("testIndent", testIndent),
    ]
}
