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

public final class ModuleTests: XCTestCase {
    public func testAvgPool1D() {
        testRoundtrip("Tests/SILTests/Resources/AvgPool1D.sil")
    }

    private func testRoundtrip(_ silPath: String) {
        do {
            guard let expectedData = FileManager.default.contents(atPath: silPath) else {
                return XCTFail("\(silPath) not found")
            }
            guard let expected = String(data: expectedData, encoding: .utf8) else {
                return XCTFail("\(silPath) not in UTF-8")
            }
            let module = try Module.parse(fromSILPath: silPath)
            let actual = module.description + "\n"
            if (expected != actual) {
                if let actualFile = FileManager.default.makeTemporaryFile() {
                    let actualPath = actualFile.path
                    FileManager.default.createFile(atPath: actualPath, contents: Data(actual.utf8))
                    if shelloutOrFail("colordiff", "-u", silPath, actualPath) {
                        XCTFail("Roundtrip failed: expected \(silPath), actual: \(actualPath)")
                    } else {
                        XCTFail("Roundtrip failed: expected \(silPath), actual: \n\(actual)")
                    }
                } else {
                    XCTFail("Roundtrip failed")
                }
            }
        } catch {
            XCTFail(String(describing: error))
        }
    }
}

extension ModuleTests {
    public static let allTests = [
        ("testAvgPool1D", testAvgPool1D),
    ]
}
