import XCTest
@testable import SIL

final class BitcodeTests: XCTestCase {
  public func withSIB(forFile: String, _ f: (URL) -> ()) {
    withTemporaryFile { tempFile in
      guard shelloutOrFail("swiftc", "-emit-sib", "-o", tempFile.path, forFile) else { return }
      f(tempFile)
    }
  }

  public func testLoadingSIB() {
    withSIB(forFile: "Tests/SILTests/Resources/AddFloat.swift") { bitcodeURL in
      guard let topBlock = try? loadSIBBitcode(fromPath: bitcodeURL.path) else {
        return XCTFail("Failed to parse the SIB file")
      }
      // NB: Don't take those asserts very seriously. Failure to satisfy them
      //     might mean that you're just using a different version of the compiler
      //     than the one that was used to write this test. SIB does not have a
      //     stable format, so it might need some adjustments in the future.
      XCTAssertEqual(topBlock.subblocks.count, 1)
      let moduleBlock = topBlock.subblocks[0]
      XCTAssertEqual(moduleBlock.subblocks.count, 7)
      let silBlock = moduleBlock.subblocks[2]
      let p = BitcodePrinter()
      p.print(silBlock)
      XCTAssertEqual(
        p.description,
        """
        <SIL_BLOCK NumWords=142 BlockCodeSize=6>
          <SIL_FUNCTION op0=0 op1=0 op2=0 op3=0 op4=0 op5=0 op6=0 op7=0 op8=4 op9=0 op10=0 op11=0 op12=0 op13=1 op14=0 op15=0 op16=0/>
          <SIL_BASIC_BLOCK op0=2 op1=768 op2=2 op3=3 op4=768 op5=3/>
          <SIL_ONE_OPERAND op0=20 op1=0 op2=4 op3=0 op4=6/>
          <SIL_ONE_TYPE_VALUES op0=87 op1=2 op2=0 op3=4 op4=0 op5=4/>
          <SIL_ONE_OPERAND op0=113 op1=0 op2=2 op3=0 op4=5/>
          <SIL_FUNCTION op0=2 op1=0 op2=0 op3=0 op4=0 op5=0 op6=0 op7=0 op8=4 op9=0 op10=0 op11=0 op12=0 op13=5 op14=0 op15=0 op16=0/>
          <SIL_BASIC_BLOCK op0=6 op1=768 op2=2/>
          <SIL_ONE_OPERAND op0=21 op1=0 op2=7 op3=0 op4=7/>
          <SIL_ONE_VALUE_ONE_OPERAND op0=88 op1=0 op2=1 op3=6 op4=0 op5=2/>
          <SIL_INST_APPLY op0=2 op1=0 op2=7 op3=0 op4=8 op5=4 op6=7 op7=0 op8=3 op9=7 op10=0/>
          <SIL_ONE_TYPE_VALUES op0=87 op1=6 op2=0 op3=7 op4=0 op5=5/>
          <SIL_ONE_OPERAND op0=113 op1=0 op2=6 op3=0 op4=6/>
        </SIL_BLOCK>

        """
      )
    }
  }

}
