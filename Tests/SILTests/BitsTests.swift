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

public final class BitsTests: XCTestCase {
    public func testIntConstructor() {
        let cases = Array(0...100) + (1...100).map { _ in Int.random(in: 0...Int.max) }
        for c in cases {
            let expected = Bits(mostFirst: Array(String(c, radix: 2)).map({ $0 == "1" }))
            XCTAssertEqual(Bits(c), expected)
        }
    }

    public func testJoin() {
        for _ in 1...100 {
            let numSequences = Int.random(in: 2...10)
            let sequences = (0..<numSequences).map { _ in randomSequence(length: 1...80) }
            XCTAssertEqual(
                Bits.join(sequences.map { Bits(leastFirst: $0) }),
                Bits(leastFirst: Array(sequences.joined())))
        }
    }

    private func randomSequence(length: ClosedRange<Int>) -> [Bool] {
        return (1...Int.random(in: length)).map { _ in Bool.random() }
    }

    public func testEqualityClasses() {
        let equalityClasses = [
            [
                Bits(3),
                Bits(mostFirst: [true, true]),
                Bits(mostFirst: [false, false, true, true])
            ],
            [
                Bits(0),
                Bits(leastFirst: [false, false, false]),
                Bits(mostFirst: [false, false, false, false, false])
            ],
            [
                Bits(5),
                Bits(mostFirst: [false, false, false, false, true, false, true])
            ]
        ]
        for (i, clsi) in equalityClasses.enumerated() {
            for (j, clsj) in equalityClasses.enumerated() {
                for ei in clsi {
                    for ej in clsj {
                        if (i == j) {
                            XCTAssertEqual(ei, ej)
                            XCTAssertEqual(ei.hashValue, ej.hashValue)
                        } else {
                            XCTAssertNotEqual(ei, ej)
                            // NB: hashValues might be equal here
                        }
                    }
                }
            }
        }
    }

    public func testEqualityWithExtraSignificantZeros() {
        for _ in 1...100 {
            let seq = randomSequence(length: 1...200)
            let paddedSeq = seq + Array(repeating: false, count: Int.random(in: 1...50))
            XCTAssertEqual(Bits(leastFirst: seq), Bits(leastFirst: paddedSeq))
            XCTAssertEqual(Bits(leastFirst: seq).hashValue, Bits(leastFirst: paddedSeq).hashValue)
        }
    }
}

extension BitsTests {
    public static let allTests = [
        ("testIntConstructor", testIntConstructor),
        ("testJoin", testJoin),
        ("testEqualityClasses", testEqualityClasses),
        ("testEqualityWithExtraSignificantZeros", testEqualityWithExtraSignificantZeros),
    ]
}
