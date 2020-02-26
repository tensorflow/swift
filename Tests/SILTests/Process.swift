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

func shellout(_ args: String...) throws -> Int32 {
    return try shellout(args)
}

func shellout(_ args: [String]) throws -> Int32 {
    // We need to have the availability annotation due to some Process shenanigans
    // present in the standard library...
    if #available(macOS 10.13, *) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = args
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    } else {
        throw ShelloutError.unavailable("shellout is unavailable on this platform")
    }
}

func shelloutOrFail(_ args: String...) -> Bool {
    let commandLine = args.joined(separator: " ")
    do {
        let status = try shellout(args)
        if status != 0 {
            XCTFail("Failed to execute \(commandLine)\nExit code: \(status))")
            return false
        }
    } catch {
        XCTFail("Failed to execute \(commandLine)\n\(String(describing: error))")
        return false
    }
    return true
}

enum ShelloutError: Error {
    case unavailable(String)
}
