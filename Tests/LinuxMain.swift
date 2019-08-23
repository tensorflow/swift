import QuoteTests
import SILTests
import XCTest

#if !SKIP_QUOTE_TESTS
let quoteTests = [
    testCase(CompilationTests.allTests),
    testCase(QuoteTests.DescriptionTests.allTests),
    testCase(StructureTests.allTests),
]
#else
let quoteTests = [XCTestCaseEntry]()
#endif

#if !SKIP_SIL_TESTS
let silTests = [
    testCase(BitcodeTests.allTests),
    testCase(BitsTests.allTests),
    testCase(BitstreamTests.allTests),
    testCase(SILTests.DescriptionTests.allTests),
    testCase(InstructionTests.allTests),
    testCase(ModuleTests.allTests),
    testCase(PrinterTests.allTests),
]
#else
let silTests = [XCTestCaseEntry]()
#endif

let tests = quoteTests + silTests
XCTMain(tests)
