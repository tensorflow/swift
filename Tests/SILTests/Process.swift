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
