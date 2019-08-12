import QuoteTests
import XCTest

let tests = [
  testCase(DescriptionTests.allTests),
  testCase(QuoteTests.allTests),
  testCase(StructureTests.allTests),
]
XCTMain(tests)
