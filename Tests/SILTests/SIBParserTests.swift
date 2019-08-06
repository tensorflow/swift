import XCTest
@testable import SIL

// We need to have the availability annotation due to some Process shenanigans
// present in the standard library...
@available(macOS 10.13, *)
final class SIBParserTests: XCTestCase {
  // TODO: deduplicate!
  public func withSIB(forFile: String, _ f: (URL) -> ()) {
    withTemporaryFile { tempFile in
      let process = Process()
      process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
      process.arguments = ["swiftc", "-emit-sib", "-o", tempFile.path, forFile]
      do {
        try process.run()
        process.waitUntilExit()
      } catch {
        return XCTFail("Failed to execute swiftc!")
      }
      f(tempFile)
    }
  }

  public func testLoadingSIB() {
    withSIB(forFile: "Tests/SILTests/Resources/AddFloat.swift") { bitcodeURL in
      guard let topBlock = try? loadSIBBitcode(fromPath: bitcodeURL.path) else {
        return XCTFail("Failed to parse the SIB file")
      }
      // FIXME: This test doesn't do anything useful
      do {
        try SIBParser(moduleBlock: topBlock.subblocks[0]).parse()
      } catch {
        print(error)
      }
    }
  }

}

