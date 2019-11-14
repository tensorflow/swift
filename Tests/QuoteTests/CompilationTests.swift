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

import Quote
import XCTest

@quoted
func foo(_ x: Float) -> Float {
    return 1 * x
}

class Bar {
    @quoted
    func instanceBar(_ x: Float) -> Float {
        return 2 * x
    }

    @quoted
    func staticBar(_ x: Float) -> Float {
        return 3 * x
    }
}

// NOTE: This is a test of whether this thing successfully compiles.
@quoted
func noReturnType() {
}

public final class CompilationTests: XCTestCase {
    public func testClosureWithExpr() {
        let q = #quote{ (x: Int, y: Int) in
            x + y
        }
        let _ = { q(40, 2) }
        assertDescription(
            q,
            """
      { (x: Int, y: Int) -> Int in
        return (x + y)
      }
      """)
        assertDescription(q.type, "(Int, Int) -> Int")
    }

    public func testClosureWithStmts() {
        let q = #quote{
            let n = 42;
            print(n)
        }
        let _ = { q() }
        assertDescription(
            q,
            """
      { () -> () in
        let n: Int = 42
        print(n)
      }
      """)
        assertDescription(q.type, "() -> ()")
    }

    public func testUnquoteManual() {
        let u = #quote{ (x: Int, y: Int) in
            x + y
        }
        let _ = { u(40, 2) }
        let q = #quote{ (x: Int) in
            #unquote(u)(x, x)
        }
        let _ = { q(42) }
        assertDescription(
            q,
            """
      { (x: Int) -> Int in
        return #unquote(u)(x, x)
      }
      """)
        assertDescription(q.type, "(Int) -> Int")
    }

    public func testUnquoteAutomatic() {
        let t1 = _quotedFoo()
        assertStructure(
            t1,
            """
      Function(
        Name(
          "foo",
          "<unstable USR>",
          FunctionType(
            [],
            [TypeName("Float", "s:Sf")],
            TypeName("Float", "s:Sf"))),
        [Parameter(
          nil,
          Name(
            "x",
            "<unstable USR>",
            TypeName("Float", "s:Sf")))],
        [Return(
          Binary(
            IntegerLiteral(
              1,
              TypeName("Float", "s:Sf")),
            Name(
              "*",
              "s:Sf1moiyS2f_SftFZ",
              FunctionType(
                [],
                [TypeName("Float", "s:Sf"),
                TypeName("Float", "s:Sf")],
                TypeName("Float", "s:Sf"))),
            Name(
              "x",
              "<unstable USR>",
              TypeName("Float", "s:Sf")),
            TypeName("Float", "s:Sf")))])
      """
        )

        let q1 = #quote(foo)
        assertStructure(
            q1,
            """
      Unquote(
        Name(
          "foo",
          "<unstable USR>",
          FunctionType(
            [],
            [TypeName("Float", "s:Sf")],
            TypeName("Float", "s:Sf"))),
        func foo(_ x: Float) -> Float in
          return (1 * x)
        },
        SpecializedType(
          TypeName("FunctionQuote1", "s:5Quote14FunctionQuote1C"),
          [TypeName("Float", "s:Sf"),
          TypeName("Float", "s:Sf")]))
      """
        )

        let t2 = Bar._quotedInstanceBar()
        assertStructure(
            t2,
            """
      Function(
        Name(
          "instanceBar",
          "<unstable USR>",
          FunctionType(
            [],
            [TypeName("Float", "s:Sf")],
            TypeName("Float", "s:Sf"))),
        [Parameter(
          nil,
          Name(
            "x",
            "<unstable USR>",
            TypeName("Float", "s:Sf")))],
        [Return(
          Binary(
            IntegerLiteral(
              2,
              TypeName("Float", "s:Sf")),
            Name(
              "*",
              "s:Sf1moiyS2f_SftFZ",
              FunctionType(
                [],
                [TypeName("Float", "s:Sf"),
                TypeName("Float", "s:Sf")],
                TypeName("Float", "s:Sf"))),
            Name(
              "x",
              "<unstable USR>",
              TypeName("Float", "s:Sf")),
            TypeName("Float", "s:Sf")))])
      """
        )

        let bar = Bar()
        blackHole(bar)
        let q2 = #quote(bar.instanceBar)
        assertStructure(
            q2,
            """
      Unquote(
        Member(
          Name(
            "bar",
            "<unstable USR>",
            TypeName("Bar", "<unstable USR>")),
          "instanceBar",
          "<unstable USR>",
          FunctionType(
            [],
            [TypeName("Float", "s:Sf")],
            TypeName("Float", "s:Sf"))),
        func instanceBar(_ x: Float) -> Float in
          return (2 * x)
        },
        SpecializedType(
          TypeName("FunctionQuote1", "s:5Quote14FunctionQuote1C"),
          [TypeName("Float", "s:Sf"),
          TypeName("Float", "s:Sf")]))
      """
        )

        let t3 = Bar._quotedStaticBar()
        assertStructure(
            t3,
            """
      Function(
        Name(
          "staticBar",
          "<unstable USR>",
          FunctionType(
            [],
            [TypeName("Float", "s:Sf")],
            TypeName("Float", "s:Sf"))),
        [Parameter(
          nil,
          Name(
            "x",
            "<unstable USR>",
            TypeName("Float", "s:Sf")))],
        [Return(
          Binary(
            IntegerLiteral(
              3,
              TypeName("Float", "s:Sf")),
            Name(
              "*",
              "s:Sf1moiyS2f_SftFZ",
              FunctionType(
                [],
                [TypeName("Float", "s:Sf"),
                TypeName("Float", "s:Sf")],
                TypeName("Float", "s:Sf"))),
            Name(
              "x",
              "<unstable USR>",
              TypeName("Float", "s:Sf")),
            TypeName("Float", "s:Sf")))])
      """
        )

        let q3 = #quote(Bar.staticBar)
        assertStructure(
            q3,
            """
      Unquote(
        Name(
          "staticBar",
          "<unstable USR>",
          FunctionType(
            [],
            [TypeName("Float", "s:Sf")],
            TypeName("Float", "s:Sf"))),
        func staticBar(_ x: Float) -> Float in
          return (3 * x)
        },
        SpecializedType(
          TypeName("FunctionQuote1", "s:5Quote14FunctionQuote1C"),
          [TypeName("Float", "s:Sf"),
          TypeName("Float", "s:Sf")]))
      """
        )
    }

    public func testAvgPool1D() {
        func threadIndex() -> Int { return 0 }
        func threadCount() -> Int { return 1 }
        let avgPool1D = #quote{
                (out: inout [Float], input: [Float], windowSize: Int, windowStride: Int) -> Void in
                let n = input.count
                let outSize = (n - windowSize) / windowStride + 1
                let outStart = threadIndex()
                let outStride = threadCount()
                for outIndex in stride(from: outStart, to: outSize, by: outStride) {
                    out[outIndex] = 0.0
                    let beginWindow = outIndex * windowStride
                    let endWindow = outIndex * windowStride + windowSize
                    for inputIndex in beginWindow..<endWindow {
                        out[outIndex] += input[inputIndex]
                    }
                    out[outIndex] /= Float(windowSize)
                }
            }
        let _ = {
            let x: [Float] = [1, 2, 3, 4, 5, 6]
            var out: [Float] = [Float](repeating: 0, count: x.count)
            let windowSize = 2
            let windowStride = 2
            avgPool1D(&out, x, windowSize, windowStride)
        }
        assertDescription(
            avgPool1D,
            """
      { (out: inout [Float], input: [Float], windowSize: Int, windowStride: Int) -> Void in
        let n: Int = input.count
        let outSize: Int = (((n - windowSize) / windowStride) + 1)
        let outStart: Int = threadIndex()
        let outStride: Int = threadCount()
        for outIndex in stride(from: outStart, to: outSize, by: outStride) {
          out[outIndex] = 0.0
          let beginWindow: Int = (outIndex * windowStride)
          let endWindow: Int = ((outIndex * windowStride) + windowSize)
          for inputIndex in (beginWindow ..< endWindow) {
            (out[outIndex] += input[inputIndex])
          }
          (out[outIndex] /= Float(windowSize))
        }
      }
      """
        )
        assertDescription(avgPool1D.type, "(inout [Float], [Float], Int, Int) -> Void")
    }

    public func test31() {
        print(#quote(42))
    }

    public func test32() {
        print(#quote(print(42)))
    }

    private func blackHole(_ x: Any) {
        // This method exists to silence unused variable warnings.
        // TODO(TF-728): Get rid of this method.
    }

    public static let allTests = [
        ("testClosureWithExpr", testClosureWithExpr),
        ("testClosureWithStmts", testClosureWithStmts),
        ("testUnquoteManual", testUnquoteManual),
        ("testUnquoteAutomatic", testUnquoteAutomatic),
        ("testAvgPool1D", testAvgPool1D),
        // NOTE: This is intentionally not run - we just need to check that the test compiles.
        // ("test31", test31),
        // ("test32", test32),
    ]
}
