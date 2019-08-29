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
