// Copyright 2019 The TensorFlow Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import XCTest

#if !SKIP_QUOTE_TESTS
import QuoteTests
let quoteTests = [
    testCase(CompilationTests.allTests),
    testCase(QuoteTests.DescriptionTests.allTests),
    testCase(StructureTests.allTests),
]
#else
let quoteTests = [XCTestCaseEntry]()
#endif

#if !SKIP_SIL_TESTS
import SILTests
let silTests = [
    testCase(BitcodeTests.allTests),
    testCase(BitsTests.allTests),
    testCase(BitstreamTests.allTests),
    testCase(SILTests.DescriptionTests.allTests),
    testCase(SILParserTests.allTests),
    testCase(InstructionTests.allTests),
    testCase(ModuleTests.allTests),
    testCase(PrinterTests.allTests),
    testCase(SExprTests.allTests),
    testCase(SILAnalysisTests.allTests),
]
#else
let silTests = [XCTestCaseEntry]()
#endif

let tests = quoteTests + silTests
XCTMain(tests)
