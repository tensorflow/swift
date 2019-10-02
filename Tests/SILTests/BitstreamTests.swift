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

public final class BitstreamTests: XCTestCase {
    public func testReads() {
        // NB: The bytes are read from left to right, the bits are read from
        //     the LSB to MSB (i.e. right to left!).
        var stream = Bitstream(Data([0b11110101, 0b01000111]))
        for i in 0..<5 {
            XCTAssertEqual(try! stream.nextBit(), i % 2 == 0)
        }
        XCTAssertEqual(try! stream.nextByte(), 0b00111111)
        for i in 5..<8 {
            XCTAssertEqual(try! stream.nextBit(), i % 2 == 0)
        }
        XCTAssertEqual(stream.isEmpty, true)
    }
}

extension BitstreamTests {
    public static let allTests = [
        ("testReads", testReads),
    ]
}
