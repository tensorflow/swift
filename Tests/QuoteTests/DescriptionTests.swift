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

public final class DescriptionTests: XCTestCase {
    public func testDifferentiable() {
        // NOTE: At the moment, this leads to a runtime crash.
        // let fn: @differentiable (Float) -> Float = { x in x }
        // blackHole(fn)
        // let q = #quote(fn)
        func fn() -> @differentiable (Float) -> Float { fatalError("") }
        let q = #quote(fn())
        assertDescription(q.type, "@differentiable (Float) -> Float")
    }

    public func testAndType() {
        func f() -> A & B { fatalError("implement me"); }
        let q = #quote(f())
        assertDescription(q.type, "A & B")
    }

    public func testArrayType() {
        let x = [1, 2, 3]
        blackHole(x)
        let q = #quote(x)
        assertDescription(q.type, "[Int]")
    }

    public func testDictionaryType() {
        let x = [40: 2]
        blackHole(x)
        let q = #quote(x)
        assertDescription(q.type, "[Int: Int]")
    }

    public func testFunctionType() {
        let x = { (x: Int) in
            x
        }
        blackHole(x)
        let q = #quote(x)
        assertDescription(q.type, "(Int) -> Int")
    }

    public func testInOutType() {
        let q = #quote{ (x: inout Int) in
            x
        }
        assertDescription(q.type, "(inout Int) -> Int")
    }

    public func testLValueType() {
        // TODO(TF-729): Find out how to conveniently test this.
    }

    public func testMetaType() {
        let x = Int.self
        blackHole(x)
        let q = #quote(x)
        assertDescription(q.type, "Int.Type")
    }

    public func testOptionalType() {
        let x: Int? = 42
        blackHole(x ?? 42)
        let q = #quote(x)
        assertDescription(q.type, "Int?")
    }

    public func testSpecializedType() {
        let x: ClosedRange<Int> = 1...10
        blackHole(x)
        let q = #quote(x)
        assertDescription(q.type, "ClosedRange[Int]")
    }

    public func testTupleType() {
        let x = (1, "2", 3)
        blackHole(x)
        let q = #quote(x)
        assertDescription(q.type, "(Int, String, Int)")
    }

    public func testTypeName() {
        let x = 42
        blackHole(x)
        let q = #quote(x)
        assertDescription(q.type, "Int")
    }

    public func testBreak() {
        let q = #quote{
            while true {
                break
            }
        }
        assertDescription(
            q,
            """
      { () -> () in
        while true {
          break
        }
      }
      """
        )
    }

    public func testContinue() {
        let q = #quote{
            while true {
                continue
            }
        }
        assertDescription(
            q,
            """
      { () -> () in
        while true {
          continue
        }
      }
      """
        )
    }

    public func testDefer() {
        let q = #quote{
            defer {}
            return
        }
        assertDescription(
            q,
            """
      { () -> () in
        defer {
        }
        return ()
      }
      """)
    }

    public func testDo() {
        let q = #quote{
            do {}
        }
        assertDescription(
            q,
            """
      { () -> () in
        do {
        }
      }
      """)
    }

    public func testFor() {
        let range = 1...10
        blackHole(range)
        let q = #quote{
            for i in range {}
        }
        assertDescription(
            q,
            """
      { () -> () in
        for i in range {
        }
      }
      """)
    }

    public func testGuard() {
        let q = #quote{
            guard true else {}
        }
        assertDescription(
            q,
            """
      { () -> () in
        guard true else {
        }
      }
      """)
    }

    public func testIf() {
        let q = #quote{
            if true {} else if false {} else {}
        }
        assertDescription(
            q,
            """
      { () -> () in
        if true {
        } else {
          if false {
          }
        }
      }
      """
        )
    }

    public func testRepeat() {
        let q = #quote{
            repeat {} while true
        }
        assertDescription(
            q,
            """
      { () -> () in
        repeat {
        } while true
      }
      """)
    }

    public func testReturn() {
        let q = #quote{ () in
            return
        }
        assertDescription(
            q,
            """
      { () -> () in
        return ()
      }
      """)
    }

    public func testThrow() {
        let q = #quote{
            throw X()
        }
        assertDescription(
            q,
            """
      { () -> () in
        throw X()
      }
      """)
    }

    public func testWhile() {
        let q = #quote{
            while true {}
        }
        assertDescription(
            q,
            """
      { () -> () in
        while true {
        }
      }
      """)
    }

    public func testArrayLiteral() {
        let q = #quote([40, 2])
        assertDescription(q, "[40, 2]")
    }

    public func testAs() {
        let q = #quote(42 as Int)
        assertDescription(q, "(42 as Int)")
    }

    public func testAssign() {
        var x = 0
        x = 42  // TODO(TF-728): Get rid of this assignment.
        blackHole(x)
        let q = #quote(x = 42)
        assertDescription(q, "x = 42")
    }

    public func testBinary() {
        let q = #quote(40 + 2)
        assertDescription(q, "(40 + 2)")
    }

    public func testBooleanLiteral() {
        let q = #quote(true)
        assertDescription(q, "true")
    }

    public func testCall1() {
        let q = #quote(print(42))
        assertDescription(q, "print(42)")
    }

    public func testCall2() {
        let q = #quote(f().m())
        assertDescription(q, "f().m()")
    }

    public func testClosure() {
        let q = #quote{ (x: Int) in
            x
        }
        assertDescription(
            q,
            """
      { (x: Int) -> Int in
        return x
      }
      """)
    }

    public func testConversion() {
        testLValueType()
    }

    public func testDefault() {
        testCall1()
    }

    public func testDictionaryLiteral() {
        let q = #quote([40: 40, 2: 2])
        assertDescription(q, "[40: 40, 2: 2]")
    }

    public func testFloatLiteral() {
        let q = #quote(42.0)
        assertDescription(q, "42.0")
    }

    public func testForce() {
        let x: Int? = 42
        blackHole(x ?? 42)
        let q = #quote(x!)
        assertDescription(q, "x!")
    }

    public func testForceAs() {
        let x: Any = 42
        blackHole(x)
        let q = #quote(x as! Int)
        assertDescription(q, "(x as! Int)")
    }

    public func testForceTry() {
        let q = #quote(try! 42)
        assertDescription(q, "try! 42")
    }

    public func testInout() {
        func foo(_ x: inout Int) {}
        var x = 0
        blackHole(x)
        x = 42  // TODO(TF-728): Get rid of this assignment.
        let q = #quote(foo(&x))
        assertDescription(q, "foo(&x)")
    }

    public func testIntegerLiteral() {
        let q = #quote(42)
        assertDescription(q, "42")
    }

    public func testIs() {
        let x: Any = 42
        blackHole(x)
        let q = #quote(x is Int)
        assertDescription(q, "(x is Int)")
    }

    public func testMagicLiteral() {
        let q1 = #quote(#file)
        assertDescription(q1, "#file")
        let q2 = #quote(#line)
        assertDescription(q2, "#line")
        let q3 = #quote(#column)
        assertDescription(q3, "#column")
        let q4 = #quote(#function)
        assertDescription(q4, "#function")
        let q5 = #quote(#dsohandle)
        assertDescription(q5, "#dsohandle")
    }

    public func testMember1() {
        let x = [1, 2, 3]
        blackHole(x)
        let q = #quote(x.count)
        assertDescription(q, "x.count")
    }

    public func testMember2() {
        let q = #quote(Context.local)
        assertDescription(q, "local")
    }

    public func testMember3() {
        let q = #quote(E.a)
        assertDescription(q, "a")
    }

    public func testMember4() {
        let q = #quote(g())
        assertDescription(q, "g()")
    }

    public func testMeta() {
        let q = #quote(#quote(42))
        assertDescription(q, "#quote(42)")
    }

    public func testName() {
        let x = 42
        blackHole(x)
        let q = #quote(x)
        assertDescription(q, "x")
    }

    public func testNilLiteral() {
        let q = #quote(nil as Int?)
        assertDescription(q, "(nil as Int?)")
    }

    public func testOptionalAs() {
        let x: Any = 42
        blackHole(x)
        let q = #quote(x as? Int)
        assertDescription(q, "(x as? Int)")
    }

    public func testOptionalTry() {
        let q = #quote(try? 42)
        assertDescription(q, "try? 42")
    }

    public func testPostfix() {
        // TODO(TF-729): Find out how to conveniently test this.
    }

    public func testPostfixSelf1() {
        let q = #quote(42.self)
        assertDescription(q, "42.self")
    }

    public func testPostfixSelf2() {
        let q = #quote(Int.self)
        assertDescription(q, "Int.self")
    }

    public func testPrefix() {
        let q = #quote(+42)
        assertDescription(q, "(+42)")
    }

    public func testStringInterpolation() {
        let x = 42
        blackHole(x)
        let q = #quote("x = \(x)")
        assertDescription(q, "\"...\"")
    }

    public func testStringLiteral() {
        let q = #quote("42")
        assertDescription(q, "\"42\"")
    }

    public func testSubscript() {
        let x = [1, 2, 3]
        blackHole(x)
        let q = #quote(x[0])
        assertDescription(q, "x[0]")
    }

    public func testSuper() {
        class C {
            func p() {}
        }
        class D: C {
            func q() {
                let q = #quote(super.p())
                assertDescription(q, "super.p()")
            }
        }
        D().q()
    }

    public func testTernary() {
        let q = #quote(true ? 40 : 2)
        assertDescription(q, "(true ? 40 : 2)")
    }

    public func testTry() {
        let q = #quote(try 42)
        assertDescription(q, "try 42")
    }

    public func testTuple() {
        let q = #quote((1, "2", 3))
        assertDescription(q, "(1, \"2\", 3)")
    }

    public func testTupleElement() {
        let q = #quote((1, 2).1)
        assertDescription(q, "(1, 2).1")
    }

    public func testUnquote() {
        let x = #quote(40)
        let q = #quote(#unquote(x)+2)
        assertDescription(q, "(#unquote(x) + 2)")
    }

    public func testVarargs() {
        testCall1()
    }

    public func testWildcard() {
        let q = #quote(_ = 42)
        assertDescription(q, "_ = 42")
    }

    public func testFunction() {
        // TODO(TF-724): Find out how to conveniently test this.
    }

    public func testLet() {
        let q = #quote{ let x = 42 }
        assertDescription(
            q,
            """
      { () -> () in
        let x: Int = 42
      }
      """)
    }

    public func testParameter() {
        testClosure()
    }

    public func testVar() {
        let q = #quote{ var x = 42 }
        assertDescription(
            q,
            """
      { () -> () in
        var x: Int = 42
      }
      """)
    }

    public func test29() {
        let q = #quote(1...10)
        assertDescription(q, "(1 ... 10)")
    }

    public func test30() {
        let x = 42
        blackHole(x)
        let q = #quote(Float(x))
        assertDescription(q, "Float(x)")
    }

    private func blackHole(_ x: Any) {
        // This method exists to silence unused variable warnings.
        // TODO(TF-728): Get rid of this method.
    }

    public static let allTests = [
        ("testDifferentiable", testDifferentiable),
        ("testAndType", testAndType),
        ("testArrayType", testArrayType),
        ("testDictionaryType", testDictionaryType),
        ("testFunctionType", testFunctionType),
        ("testInOutType", testInOutType),
        ("testLValueType", testLValueType),
        ("testMetaType", testMetaType),
        ("testOptionalType", testOptionalType),
        ("testSpecializedType", testSpecializedType),
        ("testTupleType", testTupleType),
        ("testTypeName", testTypeName),
        ("testBreak", testBreak),
        ("testContinue", testContinue),
        ("testDefer", testDefer),
        ("testDo", testDo),
        ("testFor", testFor),
        ("testGuard", testGuard),
        ("testIf", testIf),
        ("testRepeat", testRepeat),
        ("testReturn", testReturn),
        ("testThrow", testThrow),
        ("testWhile", testWhile),
        ("testArrayLiteral", testArrayLiteral),
        ("testAs", testAs),
        ("testAssign", testAssign),
        ("testBinary", testBinary),
        ("testBooleanLiteral", testBooleanLiteral),
        ("testCall1", testCall1),
        ("testCall2", testCall2),
        ("testClosure", testClosure),
        ("testConversion", testConversion),
        ("testDefault", testDefault),
        ("testDictionaryLiteral", testDictionaryLiteral),
        ("testFloatLiteral", testFloatLiteral),
        ("testForce", testForce),
        ("testForceAs", testForceAs),
        ("testForceTry", testForceTry),
        ("testInout", testInout),
        ("testIntegerLiteral", testIntegerLiteral),
        ("testIs", testIs),
        ("testMagicLiteral", testMagicLiteral),
        ("testMember1", testMember1),
        ("testMember2", testMember2),
        ("testMember3", testMember3),
        ("testMember4", testMember4),
        ("testMeta", testMeta),
        ("testName", testName),
        ("testNilLiteral", testNilLiteral),
        ("testOptionalAs", testOptionalAs),
        ("testOptionalTry", testOptionalTry),
        ("testPostfix", testPostfix),
        ("testPostfixSelf1", testPostfixSelf1),
        ("testPostfixSelf2", testPostfixSelf2),
        ("testPrefix", testPrefix),
        ("testStringInterpolation", testStringInterpolation),
        ("testStringLiteral", testStringLiteral),
        ("testSubscript", testSubscript),
        ("testSuper", testSuper),
        ("testTernary", testTernary),
        ("testTry", testTry),
        ("testTuple", testTuple),
        ("testTupleElement", testTupleElement),
        ("testUnquote", testUnquote),
        ("testVarargs", testVarargs),
        ("testWildcard", testWildcard),
        ("testFunction", testFunction),
        ("testLet", testLet),
        ("testParameter", testParameter),
        ("testVar", testVar),
        ("test29", test29),
        ("test30", test30),
    ]
}
