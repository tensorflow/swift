import QuoteTests
import SILTests
import XCTest

let tests = [
    // QuoteTests
    testCase(CompilationTests.allTests),
    testCase(QuoteTests.DescriptionTests.allTests),
    testCase(StructureTests.allTests),
    // SILTests
    testCase(BitcodeTests.allTests),
    testCase(BitsTests.allTests),
    testCase(BitstreamTests.allTests),
    testCase(SILTests.DescriptionTests.allTests),
    testCase(InstructionTests.allTests),
    testCase(ModuleTests.allTests),
    testCase(PrinterTests.allTests),
]
XCTMain(tests)
