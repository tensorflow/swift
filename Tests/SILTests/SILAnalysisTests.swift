import Foundation
import XCTest
@testable import SIL

public final class SILAnalysisTests: XCTestCase {
    public func testAlphaConverted() {
        for instructionDef in instructionDefs {
            do {
                let p = SILParser(forString: instructionDef)
                let i = try p.parseInstructionDef()
                checkValueNames(i.substituted(using: { _ in "%TEST_NAME" }))
            } catch {
                XCTFail(String(describing: error) + "\n" + instructionDef)
            }
        }
    }

    // Only allows %0 as the value name
    func checkValueNames(_ i: InstructionDef) {
      var readingValueName = false
      var name = ""
      print(i.description)
      for c in i.description {
        if c == "%" {
          name = "%"
          assert(!readingValueName)
          readingValueName = true
          continue
        }
        guard readingValueName else { continue }
        if c.isLetter || c.isNumber || c == "_" {
          name.append(c)
        } else {
          XCTAssertEqual(name, "%TEST_NAME")
          readingValueName = false
        }
      }
    }
}

extension SILAnalysisTests {
    public static let allTests = [
        ("testAlphaConverted", testAlphaConverted),
    ]
}
