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
import Foundation

extension FileManager {
    func makeTemporaryFile() -> URL? {
        let tmpDir: URL
        if #available(macOS 10.12, *) {
            tmpDir = self.temporaryDirectory
        } else {
            tmpDir = URL(fileURLWithPath: "/tmp", isDirectory: true)
        }
        let dirPath = tmpDir.appendingPathComponent("test.XXXXXX")
        return dirPath.withUnsafeFileSystemRepresentation { maybePath in
            guard let path = maybePath else { return nil }
            var mutablePath = Array(repeating: Int8(0), count: Int(PATH_MAX))
            mutablePath.withUnsafeMutableBytes { mutablePathBufferPtr in
                mutablePathBufferPtr.baseAddress!.copyMemory(
                    from: path, byteCount: Int(strlen(path)) + 1)
            }
            guard mkstemp(&mutablePath) != -1 else { return nil }
            return URL(
                fileURLWithFileSystemRepresentation: mutablePath, isDirectory: false,
                relativeTo: nil)
        }
    }
}

extension XCTestCase {
    func withTemporaryFile(f: (URL) -> ()) {
        guard let tmp = FileManager.default.makeTemporaryFile() else {
            return XCTFail("Failed to create temporary directory")
        }
        defer { try? FileManager.default.removeItem(atPath: tmp.path) }
        f(tmp)
    }
}
