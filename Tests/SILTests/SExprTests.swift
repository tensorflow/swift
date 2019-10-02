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
import SIL

public final class SExprTests: XCTestCase {
    public func testExample() {
        testRoundtrip("Tests/SILTests/Resources/Example.sexpr")
    }

    private func testRoundtrip(_ sourcePath: String) {
        do {
            guard let expectedData = FileManager.default.contents(atPath: sourcePath) else {
                return XCTFail("\(sourcePath) not found")
            }
            guard let expected = String(data: expectedData, encoding: .utf8) else {
                return XCTFail("\(sourcePath) not in UTF-8")
            }
            let sexpr = try SExpr.parse(fromPath: sourcePath)
            let actual = sexpr.description + "\n"
            if normalize(expected) != actual {
                if let actualFile = FileManager.default.makeTemporaryFile() {
                    let actualPath = actualFile.path
                    FileManager.default.createFile(atPath: actualPath, contents: Data(actual.utf8))
                    if shelloutOrFail("colordiff", "-u", sourcePath, actualPath) {
                        XCTFail("Roundtrip failed: expected \(sourcePath), actual: \(actualPath)")
                    } else {
                        XCTFail("Roundtrip failed: expected \(sourcePath), actual: \n\(actual)")
                    }
                } else {
                    XCTFail("Roundtrip failed")
                }
            }
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func normalize(_ s: String) -> String {
      return s.replacingOccurrences(of: "\"", with: "'")
    }
}

extension SExprTests {
    public static let allTests = [
        ("testExample", testExample),
    ]
}

