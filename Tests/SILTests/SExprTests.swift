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
            print(normalize(expected))
            print(actual)
            if (normalize(expected) != actual) {
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

