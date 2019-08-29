import XCTest
@testable import SIL

public final class PrinterTests: XCTestCase {
    public func testIndent() {
        let p = Printer()
        p.print("line")
        p.indent()
        p.print(" #1\n")
        p.print("line #2\n")
        p.print("line #3\n\nline #5\n")
        p.print("\n")
        p.print("line #7")
        p.print("\n\n")
        p.unindent()
        p.print("line #9")
        XCTAssertEqual(
            p.description,
            """
      line #1
        line #2
        line #3

        line #5

        line #7

      line #9
      """
        )
    }
}

extension PrinterTests {
    public static let allTests = [
        ("testIndent", testIndent),
    ]
}
