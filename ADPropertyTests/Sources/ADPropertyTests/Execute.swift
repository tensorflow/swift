import Foundation

/// Results of compiling and executing a project.
struct ExecutionResult {
    /// Overall status.
    var status: ExecutionStatus = .success

    /// Outputs from compile steps.
    var compile: [ExecutionOut] = []

    /// Outputs from run steps.
    var runtime: [ExecutionOut] = []

    /// Tests whether outputs from compile or run steps contain the given string.
    func contains(_ substr: String) -> Bool {
        return compile.contains { $0.contains(substr) } || runtime.contains { $0.contains(substr) }
    }
}

extension ProjectNode {
    /// Compile the project and return the result of compilation.
    func compile(swiftc: String) -> ExecutionResult {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(
            "ad_prop_test_\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: false)

        for module in modules {
            for file in module.files {
                let filePath = dir.appendingPathComponent("\(file)")
                try! file.code.write(to: filePath, atomically: false, encoding: .utf8)
            }
        }

        var result = ExecutionResult()
        for module in modules {
            let fileNames = module.files.map { "\($0)" }
            guard fileNames.count > 0 else { continue }
            let moduleFilename = "\(module).swiftmodule"
            let libFilename = "lib\(module).so"
            let compileResult = runProcess(
                executable: swiftc,
                args: [
                    "-O",
                    "-emit-module",
                    "-module-name",
                    "\(module)",
                    "-emit-module-path",
                    "\(dir.appendingPathComponent(moduleFilename).path)",
                    "-emit-library",
                    "-o",
                    "\(dir.appendingPathComponent(libFilename).path)",
                    "-I",
                    "\(dir.path)",
                ] + fileNames.map { dir.appendingPathComponent($0).path },
                timeout: 300)
            result.record(compileResult: compileResult)

            if !result.status.isSuccess {
                // Intentionally don't clear the temp dir on failures.
                return result
            }
        }

        try! FileManager.default.removeItem(at: dir)
        return result
    }
}

extension ExecutionResult {
    fileprivate mutating func record(compileResult: ProcessResult) {
        assert(status.isSuccess)
        switch compileResult {
        case .timeout:
            status = .compileTimeout
        case .terminated(status: let code, out: let out):
            compile.append(out)
            if code == 1 {
                status = .compileError
            }
            if code > 1 {
                status = .compileCrash
            }
        }
    }

    fileprivate mutating func record(runtimeResult: ProcessResult) {
        assert(status.isSuccess)
        switch runtimeResult {
        case .timeout:
            status = .runtimeTimeout
        case .terminated(status: let code, out: let out):
            runtime.append(out)
            if code == 1 {
                status = .runtimeTestFailure
            }
            if code > 1 {
                status = .runtimeCrash
            }
        }
    }
}

extension ExecutionResult: CustomStringConvertible {
    var description: String {
        var result = ""
        for (index, out) in compile.enumerated() {
            if out.stdout.count > 0 {
                result += "compile \(index) stdout:\n"
                result += out.stdout
                result += "\n"
            }
            if out.stderr.count > 0 {
                result += "compile \(index) stderr:\n"
                result += out.stderr
                result += "\n"
            }
        }
        for (index, out) in runtime.enumerated() {
            if out.stdout.count > 0 {
                result += "runtime \(index) stdout:\n"
                result += out.stdout
                result += "\n"
            }
            if out.stderr.count > 0 {
                result += "runtime \(index) stderr:\n"
                result += out.stderr
                result += "\n"
            }
        }
        result += "overall status: \(status)\n"
        return result
    }
}

enum ExecutionStatus {
    case success
    case runtimeTestFailure
    case runtimeCrash
    case runtimeTimeout
    case compileError
    case compileCrash
    case compileTimeout

    var isSuccess: Bool { return self == .success }
    var isFailure: Bool { return !isSuccess }
}

struct ExecutionOut {
    var stdout: String
    var stderr: String
}

extension ExecutionOut {
    fileprivate func contains(_ substr: String) -> Bool {
        return stdout.contains(substr) || stderr.contains(substr)
    }
}

fileprivate enum ProcessResult {
    case timeout
    case terminated(status: Int32, out: ExecutionOut)
}

struct ProcessCommand {
    let command: String
}

fileprivate func runProcess(executable: String, args: [String], timeout: TimeInterval)
    -> ProcessResult
{
    let command = ProcessCommand(command: ([executable] + args).joined(separator: " "))
    print("Running \(command.command)")

    let task = Process()
    task.executableURL = URL(string: executable)
    task.arguments = args

    var stdout = ""
    var stderr = ""
    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    task.standardOutput = stdoutPipe
    task.standardError = stderrPipe
    stdoutPipe.fileHandleForReading.readabilityHandler = {
        stdout += String(data: $0.availableData, encoding: .utf8)!
    }
    stderrPipe.fileHandleForReading.readabilityHandler = {
        stderr += String(data: $0.availableData, encoding: .utf8)!
    }

    let timesOutAt = Date() + timeout
    try! task.run()

    while task.isRunning && Date() < timesOutAt {
        Thread.sleep(forTimeInterval: 0.1)
    }

    if task.isRunning {
        // TODO: None of this seems to actually terminate timedout tasks. Maybe try kill -9?

        task.terminate()

        let killTask = Process()
        killTask.executableURL = URL(string: "/usr/bin/kill")
        killTask.arguments = ["\(task.processIdentifier)"]
        try! killTask.run()

        return .timeout
    }

    stdoutPipe.fileHandleForReading.readabilityHandler = nil
    stderrPipe.fileHandleForReading.readabilityHandler = nil

    return .terminated(
        status: task.terminationStatus,
        out: ExecutionOut(stdout: stdout, stderr: stderr))
}
