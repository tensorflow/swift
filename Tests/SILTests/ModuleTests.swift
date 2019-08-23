import Foundation
import XCTest
import SIL

public final class ModuleTests: XCTestCase {
    public func testAvgPool1D() {
        testRoundtrip("Tests/SILTests/Resources/AvgPool1D.sil")
    }

    private func testRoundtrip(_ silPath: String) {
        do {
            let expected = stripUnsupportedSILSyntax(silPath)
            let module = try Module.parse(fromSILPath: silPath)
            let actual = module.description + "\n"
            if (expected != actual) {
                if let actualFile = FileManager.default.makeTemporaryFile() {
                    let actualPath = actualFile.path
                    FileManager.default.createFile(atPath: actualPath, contents: Data(actual.utf8))
                    XCTFail("Roundtrip failed: expected \(silPath), actual: \(actualPath)")
                    let _ = try? shellout("colordiff", "-u", silPath, actualPath)
                } else {
                    XCTFail("Roundtrip failed")
                }
            }
        } catch {
            XCTFail(String(describing: error))
        }
    }

    private func stripUnsupportedSILSyntax(_ silPath: String) -> String {
        let silURL = URL(fileURLWithPath: silPath)
        let contents = String(
            data: FileManager.default.contents(atPath: silPath)!, encoding: .utf8)!
        let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)

        let noHeader = lines.drop(while: { !$0.hasPrefix("sil ") })
        let noFooter = noHeader.prefix { !$0.hasPrefix("sil_witness_table ") }
        let noFullyCommentedLines = noFooter.filter { (line: Substring) -> Bool in
            let trimmedLeft = line.drop(while: { $0.isWhitespace })
            return !trimmedLeft.hasPrefix("//")
        }
        let noComments = noFullyCommentedLines.map { (line: Substring) -> String in
            let noComment = line.components(separatedBy: "//")[0]
            return noComment.replacingOccurrences(
                of: "\\s+$", with: "", options: .regularExpression)
        }

        let strippedContents = noComments.joined(separator: "\n")
        try! strippedContents.write(to: silURL, atomically: true, encoding: .utf8)
        return strippedContents
    }
}

extension ModuleTests {
    public static let allTests = [
        ("testAvgPool1D", testAvgPool1D),
    ]
}
