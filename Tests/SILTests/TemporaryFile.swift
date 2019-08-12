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
