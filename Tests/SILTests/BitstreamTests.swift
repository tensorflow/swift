import XCTest
@testable import SIL

public final class BitstreamTests: XCTestCase {
    public func testReads() {
        // NB: The bytes are read from left to right, the bits are read from
        //     the LSB to MSB (i.e. right to left!).
        var stream = Bitstream(Data([0b11110101, 0b01000111]))
        for i in 0..<5 {
            XCTAssertEqual(try! stream.nextBit(), i % 2 == 0)
        }
        XCTAssertEqual(try! stream.nextByte(), 0b00111111)
        for i in 5..<8 {
            XCTAssertEqual(try! stream.nextBit(), i % 2 == 0)
        }
        XCTAssertEqual(stream.isEmpty, true)
    }
}

extension BitstreamTests {
    public static let allTests = [
        ("testReads", testReads),
    ]
}
