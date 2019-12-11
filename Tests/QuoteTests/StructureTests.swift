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

public final class StructureTests: XCTestCase {
    public func testDifferentiable() {
        // NOTE: At the moment, this leads to a runtime crash.
        // let fn: @differentiable (Float) -> Float = { x in x }
        // blackHole(fn)
        // let q = #quote(fn)
        func fn() -> @differentiable (Float) -> Float { fatalError("") }
        let q = #quote(fn())
        assertStructure(
            q.type,
            """
      FunctionType(
        [Differentiable()],
        [TypeName("Float", "s:Sf")],
        TypeName("Float", "s:Sf"))
      """
        )
    }

    public func testAndType() {
        func f() -> A & B { fatalError("implement me"); }
        let q = #quote(f())
        assertStructure(
            q.type,
            """
      AndType(
        [TypeName("A", "<unstable USR>"),
        TypeName("B", "<unstable USR>")])
      """
        )
    }

    public func testArrayType() {
        let x = [1, 2, 3]
        blackHole(x)
        let q = #quote(x)
        assertStructure(
            q.type,
            """
      ArrayType(
        TypeName("Int", "s:Si"))
      """)
    }

    public func testDictionaryType() {
        let x = [40: 2]
        blackHole(x)
        let q = #quote(x)
        assertStructure(
            q.type,
            """
      DictionaryType(
        TypeName("Int", "s:Si"),
        TypeName("Int", "s:Si"))
      """
        )
    }

    public func testFunctionType() {
        let x = { (x: Int) in
            x
        }
        blackHole(x)
        let q = #quote(x)
        assertStructure(
            q.type,
            """
      FunctionType(
        [],
        [TypeName("Int", "s:Si")],
        TypeName("Int", "s:Si"))
      """
        )
    }

    public func testInOutType() {
        let q = #quote{ (x: inout Int) in
            x
        }
        assertStructure(
            q.type,
            """
      FunctionType(
        [],
        [InoutType(
          TypeName("Int", "s:Si"))],
        TypeName("Int", "s:Si"))
      """
        )
    }

    public func testLValueType() {
        func foo(_ x: inout Int) {
            let q = #quote{ let y = x }
            assertStructure(
                q,
                """
        Closure(
          [],
          [Let(
            Name(
              "y",
              "<unstable USR>",
              TypeName("Int", "s:Si")),
            Conversion(
              Name(
                "x",
                "<unstable USR>",
                LValueType(
                  TypeName("Int", "s:Si"))),
              TypeName("Int", "s:Si")))],
          FunctionType(
            [],
            [],
            TupleType(
              [])))
        """
            )
        }
        var x = 2
        foo(&x)
    }

    public func testMetaType() {
        let x = Int.self
        blackHole(x)
        let q = #quote(x)
        assertStructure(
            q.type,
            """
      MetaType(
        TypeName("Int", "s:Si"))
      """
        )
    }

    public func testOptionalType() {
        let x: Int? = 42
        blackHole(x ?? 42)
        let q = #quote(x)
        assertStructure(
            q.type,
            """
      OptionalType(
        TypeName("Int", "s:Si"))
      """
        )
    }

    public func testSpecializedType() {
        let x: ClosedRange<Int> = 1...10
        blackHole(x)
        let q = #quote(x)
        assertStructure(
            q.type,
            """
      SpecializedType(
        TypeName("ClosedRange", "s:SN"),
        [TypeName("Int", "s:Si")])
      """
        )
    }

    public func testTupleType() {
        let x = (1, "2", 3)
        blackHole(x)
        let q = #quote(x)
        assertStructure(
            q.type,
            """
      TupleType(
        [TypeName("Int", "s:Si"),
        TypeName("String", "s:SS"),
        TypeName("Int", "s:Si")])
      """
        )
    }

    public func testTypeName() {
        let x = 42
        blackHole(x)
        let q = #quote(x)
        assertStructure(
            q.type,
            """
      TypeName("Int", "s:Si")
      """)
    }

    public func testBreak() {
        let q = #quote{
            while true {
                break
            }
        }
        assertStructure(
            q,
            """
      Closure(
        [],
        [While(
          nil,
          [BooleanLiteral(
            true,
            TypeName("Bool", "s:Sb"))],
          [Break(
            nil)])],
        FunctionType(
          [],
          [],
          TupleType(
            [])))
      """
        )
    }

    public func testContinue() {
        let q = #quote{
            while true {
                continue
            }
        }
        assertStructure(
            q,
            """
      Closure(
        [],
        [While(
          nil,
          [BooleanLiteral(
            true,
            TypeName("Bool", "s:Sb"))],
          [Continue(
            nil)])],
        FunctionType(
          [],
          [],
          TupleType(
            [])))
      """
        )
    }

    public func testDefer() {
        let q = #quote{
            defer {}
            return
        }
        assertStructure(
            q,
            """
      Closure(
        [],
        [Defer(
          []),
        Return(
          Tuple(
            [],
            [],
            TupleType(
              [])))],
        FunctionType(
          [],
          [],
          TupleType(
            [])))
      """
        )
    }

    public func testDo() {
        let q = #quote{
            do {}
        }
        assertStructure(
            q,
            """
      Closure(
        [],
        [Do(
          nil,
          [])],
        FunctionType(
          [],
          [],
          TupleType(
            [])))
      """
        )
    }

    public func testFor() {
        let range = 1...10
        blackHole(range)
        let q = #quote{
            for i in range {}
        }
        assertStructure(
            q,
            """
      Closure(
        [],
        [For(
          nil,
          Name(
            "i",
            "<unstable USR>",
            TypeName("Element", "s:SNsSxRzSZ6StrideRpzrlE7Elementa")),
          Name(
            "range",
            "<unstable USR>",
            SpecializedType(
              TypeName("ClosedRange", "s:SN"),
              [TypeName("Int", "s:Si")])),
          [])],
        FunctionType(
          [],
          [],
          TupleType(
            [])))
      """
        )
    }

    public func testGuard() {
        let q = #quote{
            guard true else {}
        }
        assertStructure(
            q,
            """
      Closure(
        [],
        [Guard(
          [BooleanLiteral(
            true,
            TypeName("Bool", "s:Sb"))],
          [])],
        FunctionType(
          [],
          [],
          TupleType(
            [])))
      """
        )
    }

    public func testIf() {
        let q = #quote{
            if true {} else if false {} else {}
        }
        assertStructure(
            q,
            """
      Closure(
        [],
        [If(
          nil,
          [BooleanLiteral(
            true,
            TypeName("Bool", "s:Sb"))],
          [],
          [If(
            nil,
            [BooleanLiteral(
              false,
              TypeName("Bool", "s:Sb"))],
            [],
            [])])],
        FunctionType(
          [],
          [],
          TupleType(
            [])))
      """
        )
    }

    public func testRepeat() {
        let q = #quote{
            repeat {} while true
        }
        assertStructure(
            q,
            """
      Closure(
        [],
        [Repeat(
          nil,
          [],
          BooleanLiteral(
            true,
            TypeName("Bool", "s:Sb")))],
        FunctionType(
          [],
          [],
          TupleType(
            [])))
      """
        )
    }

    public func testReturn() {
        let q = #quote{ () in
            return
        }
        assertStructure(
            q,
            """
      Closure(
        [],
        [Return(
          Tuple(
            [],
            [],
            TupleType(
              [])))],
        FunctionType(
          [],
          [],
          TupleType(
            [])))
      """
        )
    }

    public func testThrow() {
      //   let q = #quote{
      //       throw X()
      //   }
      //   assertStructure(
      //       q,
      //       """
      // Closure(
      //   [],
      //   [Throw(
      //     Conversion(
      //       Call(
      //         Name(
      //           "X",
      //           "<unstable USR>",
      //           FunctionType(
      //             [],
      //             [],
      //             TypeName("X", "<unstable USR>"))),
      //         [],
      //         [],
      //         TypeName("X", "<unstable USR>")),
      //       TypeName("Error", "s:s5ErrorP")))],
      //   FunctionType(
      //     [],
      //     [],
      //     TupleType(
      //       [])))
      // """
      //   )
      // TODO(TF-1049): Unflake this test.
    }

    public func testWhile() {
        let q = #quote{
            while true {}
        }
        assertStructure(
            q,
            """
      Closure(
        [],
        [While(
          nil,
          [BooleanLiteral(
            true,
            TypeName("Bool", "s:Sb"))],
          [])],
        FunctionType(
          [],
          [],
          TupleType(
            [])))
      """
        )
    }

    public func testArrayLiteral() {
        let q = #quote([40, 2])
        assertStructure(
            q,
            """
      ArrayLiteral(
        [IntegerLiteral(
          40,
          TypeName("Int", "s:Si")),
        IntegerLiteral(
          2,
          TypeName("Int", "s:Si"))],
        ArrayType(
          TypeName("Int", "s:Si")))
      """
        )
    }

    public func testAs() {
        let q = #quote(42 as Int)
        assertStructure(
            q,
            """
      As(
        IntegerLiteral(
          42,
          TypeName("Int", "s:Si")),
        TypeName("Int", "s:Si"))
      """
        )
    }

    public func testAssign() {
        var x = 0
        x = 42  // TODO(TF-728): Get rid of this assignment.
        blackHole(x)
        let q = #quote(x = 42)
        assertStructure(
            q,
            """
      Assign(
        Name(
          "x",
          "<unstable USR>",
          LValueType(
            TypeName("Int", "s:Si"))),
        IntegerLiteral(
          42,
          TypeName("Int", "s:Si")),
        TupleType(
          []))
      """
        )
    }

    public func testBinary() {
        let q = #quote(40 + 2)
        assertStructure(
            q,
            """
      Binary(
        IntegerLiteral(
          40,
          TypeName("Int", "s:Si")),
        Name(
          "+",
          "s:Si1poiyS2i_SitFZ",
          FunctionType(
            [],
            [TypeName("Int", "s:Si"),
            TypeName("Int", "s:Si")],
            TypeName("Int", "s:Si"))),
        IntegerLiteral(
          2,
          TypeName("Int", "s:Si")),
        TypeName("Int", "s:Si"))
      """
        )
    }

    public func testBooleanLiteral() {
        let q = #quote(true)
        assertStructure(
            q,
            """
      BooleanLiteral(
        true,
        TypeName("Bool", "s:Sb"))
      """)
    }

    public func testCall1() {
        let q = #quote(print(42))
        assertStructure(
            q,
            """
      Call(
        Name(
          "print",
          "s:s5print_9separator10terminatoryypd_S2StF",
          FunctionType(
            [],
            [AndType(
              []),
            TypeName("String", "s:SS"),
            TypeName("String", "s:SS")],
            TupleType(
              []))),
        [nil],
        [Varargs(
          [Conversion(
            IntegerLiteral(
              42,
              TypeName("Int", "s:Si")),
            AndType(
              []))],
          ArrayType(
            AndType(
              []))),
        Default(
          "",
          TypeName("String", "s:SS")),
        Default(
          "",
          TypeName("String", "s:SS"))],
        TupleType(
          []))
      """
        )
    }

    public func testCall2() {
        let q = #quote(f().m())
        assertStructure(
            q,
            """
      Call(
        Member(
          Call(
            Name(
              "f",
              "<unstable USR>",
              FunctionType(
                [],
                [],
                TypeName("P", "<unstable USR>"))),
            [],
            [],
            TypeName("P", "<unstable USR>")),
          "m",
          "<unstable USR>",
          FunctionType(
            [],
            [],
            TupleType(
              []))),
        [],
        [],
        TupleType(
          []))
      """
        )
    }

    public func testClosure() {
        let q = #quote{ (x: Int) in
            x
        }
        assertStructure(
            q,
            """
      Closure(
        [Parameter(
          nil,
          Name(
            "x",
            "<unstable USR>",
            TypeName("Int", "s:Si")))],
        [Return(
          Name(
            "x",
            "<unstable USR>",
            TypeName("Int", "s:Si")))],
        FunctionType(
          [],
          [TypeName("Int", "s:Si")],
          TypeName("Int", "s:Si")))
      """
        )
    }

    public func testConversion() {
        testLValueType()
    }

    public func testDefault() {
        testCall1()
    }

    public func testDictionaryLiteral() {
        let q = #quote([40: 40, 2: 2])
        assertStructure(
            q,
            """
      DictionaryLiteral(
        [IntegerLiteral(
          40,
          TypeName("Int", "s:Si")),
        IntegerLiteral(
          40,
          TypeName("Int", "s:Si")),
        IntegerLiteral(
          2,
          TypeName("Int", "s:Si")),
        IntegerLiteral(
          2,
          TypeName("Int", "s:Si"))],
        DictionaryType(
          TypeName("Int", "s:Si"),
          TypeName("Int", "s:Si")))
      """
        )
    }

    public func testFloatLiteral() {
        let q = #quote(42.0)
        assertStructure(
            q,
            """
      FloatLiteral(
        42.0,
        TypeName("Double", "s:Sd"))
      """)
    }

    public func testForce() {
        let x: Int? = 42
        blackHole(x ?? 42)
        let q = #quote(x!)
        assertStructure(
            q,
            """
      Force(
        Name(
          "x",
          "<unstable USR>",
          OptionalType(
            TypeName("Int", "s:Si"))),
        TypeName("Int", "s:Si"))
      """
        )
    }

    public func testForceAs() {
        let x: Any = 42
        blackHole(x)
        let q = #quote(x as! Int)
        assertStructure(
            q,
            """
      ForceAs(
        Name(
          "x",
          "<unstable USR>",
          AndType(
            [])),
        TypeName("Int", "s:Si"))
      """
        )
    }

    public func testForceTry() {
        let q = #quote(try! 42)
        assertStructure(
            q,
            """
      ForceTry(
        IntegerLiteral(
          42,
          TypeName("Int", "s:Si")),
        TypeName("Int", "s:Si"))
      """
        )
    }

    public func testInout() {
        func foo(_ x: inout Int) {}
        var x = 0
        blackHole(x)
        x = 42  // TODO(TF-728): Get rid of this assignment.
        let q = #quote(foo(&x))
        assertStructure(
            q,
            """
      Call(
        Name(
          "foo",
          "<unstable USR>",
          FunctionType(
            [],
            [InoutType(
              TypeName("Int", "s:Si"))],
            TupleType(
              []))),
        [nil],
        [InOut(
          Name(
            "x",
            "<unstable USR>",
            LValueType(
              TypeName("Int", "s:Si"))),
          InoutType(
            TypeName("Int", "s:Si")))],
        TupleType(
          []))
      """
        )
    }

    public func testIntegerLiteral() {
        let q = #quote(42)
        assertStructure(
            q,
            """
      IntegerLiteral(
        42,
        TypeName("Int", "s:Si"))
      """)
    }

    public func testIs() {
        let x: Any = 42
        blackHole(x)
        let q = #quote(x is Int)
        assertStructure(
            q,
            """
      Is(
        Name(
          "x",
          "<unstable USR>",
          AndType(
            [])),
        TypeName("Int", "s:Si"),
        TypeName("Bool", "s:Sb"))
      """
        )
    }

    public func testMagicLiteral() {
        let q1 = #quote(#file)
        assertStructure(
            q1,
            """
      MagicLiteral(
        "file",
        TypeName("String", "s:SS"))
      """)

        let q2 = #quote(#line)
        assertStructure(
            q2,
            """
      MagicLiteral(
        "line",
        TypeName("Int", "s:Si"))
      """)

        let q3 = #quote(#column)
        assertStructure(
            q3,
            """
      MagicLiteral(
        "column",
        TypeName("Int", "s:Si"))
      """)

        let q4 = #quote(#function)
        assertStructure(
            q4,
            """
      MagicLiteral(
        "function",
        TypeName("String", "s:SS"))
      """
        )

        let q5 = #quote(#dsohandle)
        assertStructure(
            q5,
            """
      MagicLiteral(
        "dsohandle",
        TypeName("UnsafeRawPointer", "s:SV"))
      """
        )
    }

    public func testMember1() {
        let x = [1, 2, 3]
        blackHole(x)
        let q = #quote(x.count)
        assertStructure(
            q,
            """
      Member(
        Name(
          "x",
          "<unstable USR>",
          ArrayType(
            TypeName("Int", "s:Si"))),
        "count",
        "s:Sa5countSivp",
        TypeName("Int", "s:Si"))
      """
        )
    }

    public func testMember2() {
        let q = #quote(Context.local)
        assertStructure(
            q,
            """
      Name(
        "local",
        "<unstable USR>",
        TypeName("Context", "<unstable USR>"))
      """
        )
    }

    public func testMember3() {
        let q = #quote(E.a)
        assertStructure(
            q,
            """
      Name(
        "a",
        "<unstable USR>",
        TypeName("E", "<unstable USR>"))
      """
        )
    }

    public func testMember4() {
        let q = #quote(g())
        assertStructure(
            q,
            """
      Call(
        Name(
          "g",
          "<unstable USR>",
          FunctionType(
            [],
            [],
            TupleType(
              []))),
        [],
        [],
        TupleType(
          []))
      """
        )
    }

    public func testMeta() {
        let q = #quote(#quote(42))
        assertStructure(
            q,
            """
      Meta(
        IntegerLiteral(
          42,
          TypeName("Int", "s:Si")),
        SpecializedType(
          TypeName("Quote", "s:5QuoteAAC"),
          [TypeName("Int", "s:Si")]))
      """
        )
    }

    public func testName() {
        let x = 42
        blackHole(x)
        let q = #quote(x)
        assertStructure(
            q,
            """
      Name(
        "x",
        "<unstable USR>",
        TypeName("Int", "s:Si"))
      """
        )
    }

    public func testNilLiteral() {
        let q = #quote(nil as Int?)
        assertStructure(
            q,
            """
      As(
        NilLiteral(
          OptionalType(
            TypeName("Int", "s:Si"))),
        OptionalType(
          TypeName("Int", "s:Si")))
      """
        )
    }

    public func testOptionalAs() {
        let x: Any = 42
        blackHole(x)
        let q = #quote(x as? Int)
        assertStructure(
            q,
            """
      OptionalAs(
        Name(
          "x",
          "<unstable USR>",
          AndType(
            [])),
        TypeName("Int", "s:Si"),
        OptionalType(
          TypeName("Int", "s:Si")))
      """
        )
    }

    public func testOptionalTry() {
        //   let q = #quote(try? 42)
        //   assertStructure(
        //       q,
        //       """
        // OptionalTry(
        //   IntegerLiteral(
        //     42,
        //     TypeName("Int", "s:Si")),
        //   OptionalType(
        //     TypeName("Int", "s:Si")))
        // """
        //   )
        // TODO(TF-763): Unflake this test.
    }

    public func testPostfix() {
        // TODO(TF-729): Find out how to conveniently test this.
    }

    public func testPostfixSelf1() {
        let q = #quote(42.self)
        assertStructure(
            q,
            """
      PostfixSelf(
        IntegerLiteral(
          42,
          TypeName("Int", "s:Si")),
        TypeName("Int", "s:Si"))
      """
        )
    }

    public func testPostfixSelf2() {
        let q = #quote(Int.self)
        assertStructure(
            q,
            """
      PostfixSelf(
        TypeName("Int", "s:Si"),
        MetaType(
          TypeName("Int", "s:Si")))
      """
        )
    }

    public func testPrefix() {
        let q = #quote(+42)
        assertStructure(
            q,
            """
      Prefix(
        Name(
          "+",
          "s:s18AdditiveArithmeticPsE1popyxxFZ",
          FunctionType(
            [],
            [TypeName("Int", "s:Si")],
            TypeName("Int", "s:Si"))),
        IntegerLiteral(
          42,
          TypeName("Int", "s:Si")),
        TypeName("Int", "s:Si"))
      """
        )
    }

    public func testStringInterpolation() {
        let x = 42
        blackHole(x)
        let q = #quote("x = \(x)")
        assertStructure(
            q,
            """
      StringInterpolation(
        TypeName("String", "s:SS"))
      """)
    }

    public func testStringLiteral() {
        let q = #quote("42")
        assertStructure(
            q,
            """
      StringLiteral(
        "42",
        TypeName("String", "s:SS"))
      """)
    }

    public func testSubscript() {
        let x = [1, 2, 3]
        blackHole(x)
        let q = #quote(x[0])
        assertStructure(
            q,
            """
      Subscript(
        Name(
          "x",
          "<unstable USR>",
          ArrayType(
            TypeName("Int", "s:Si"))),
        "s:SayxSicip",
        [nil],
        [IntegerLiteral(
          0,
          TypeName("Int", "s:Si"))],
        TypeName("Int", "s:Si"))
      """
        )
    }

    public func testSuper() {
        class C {
            func p() {}
        }
        class D: C {
            func q() {
                let q = #quote(super.p())
                assertStructure(
                    q,
                    """
          Call(
            Member(
              Super(
                TypeName("C", "<unstable USR>")),
              "p",
              "<unstable USR>",
              FunctionType(
                [],
                [],
                TupleType(
                  []))),
            [],
            [],
            TupleType(
              []))
          """
                )
            }
        }
        D().q()
    }

    public func testTernary() {
        let q = #quote(true ? 40 : 2)
        assertStructure(
            q,
            """
      Ternary(
        BooleanLiteral(
          true,
          TypeName("Bool", "s:Sb")),
        IntegerLiteral(
          40,
          TypeName("Int", "s:Si")),
        IntegerLiteral(
          2,
          TypeName("Int", "s:Si")),
        TypeName("Int", "s:Si"))
      """
        )
    }

    public func testTry() {
        let q = #quote(try 42)
        assertStructure(
            q,
            """
      Try(
        IntegerLiteral(
          42,
          TypeName("Int", "s:Si")),
        TypeName("Int", "s:Si"))
      """
        )
    }

    public func testTuple() {
        let q = #quote((1, "2", 3))
        assertStructure(
            q,
            """
      Tuple(
        [],
        [IntegerLiteral(
          1,
          TypeName("Int", "s:Si")),
        StringLiteral(
          "2",
          TypeName("String", "s:SS")),
        IntegerLiteral(
          3,
          TypeName("Int", "s:Si"))],
        TupleType(
          [TypeName("Int", "s:Si"),
          TypeName("String", "s:SS"),
          TypeName("Int", "s:Si")]))
      """
        )
    }

    public func testTupleElement() {
        let q = #quote((1, 2).1)
        assertStructure(
            q,
            """
      TupleElement(
        Tuple(
          [],
          [IntegerLiteral(
            1,
            TypeName("Int", "s:Si")),
          IntegerLiteral(
            2,
            TypeName("Int", "s:Si"))],
          UnknownTree()),
        1,
        TypeName("Int", "s:Si"))
      """
        )
    }

    public func testUnquote() {
        let x = #quote(40)
        let q = #quote(#unquote(x)+2)
        assertStructure(
            q,
            """
      Binary(
        Unquote(
          Name(
            "x",
            "<unstable USR>",
            SpecializedType(
              TypeName("Quote", "s:5QuoteAAC"),
              [TypeName("Int", "s:Si")])),
          40,
          TypeName("Int", "s:Si")),
        Name(
          "+",
          "s:Si1poiyS2i_SitFZ",
          FunctionType(
            [],
            [TypeName("Int", "s:Si"),
            TypeName("Int", "s:Si")],
            TypeName("Int", "s:Si"))),
        IntegerLiteral(
          2,
          TypeName("Int", "s:Si")),
        TypeName("Int", "s:Si"))
      """
        )
    }

    public func testVarargs() {
        testCall1()
    }

    public func testWildcard() {
        let q = #quote(_ = 42)
        assertStructure(
            q,
            """
      Assign(
        Wildcard(),
        IntegerLiteral(
          42,
          TypeName("Int", "s:Si")),
        TupleType(
          []))
      """
        )
    }

    public func testFunction() {
        // TODO(TF-724): Find out how to conveniently test this.
    }

    public func testLet() {
        let q = #quote{ let x = 42 }
        assertStructure(
            q,
            """
      Closure(
        [],
        [Let(
          Name(
            "x",
            "<unstable USR>",
            TypeName("Int", "s:Si")),
          IntegerLiteral(
            42,
            TypeName("Int", "s:Si")))],
        FunctionType(
          [],
          [],
          TupleType(
            [])))
      """
        )
    }

    public func testParameter() {
        testClosure()
    }

    public func testVar() {
        let q = #quote{ var x = 42 }
        assertStructure(
            q,
            """
      Closure(
        [],
        [Var(
          Name(
            "x",
            "<unstable USR>",
            TypeName("Int", "s:Si")),
          IntegerLiteral(
            42,
            TypeName("Int", "s:Si")))],
        FunctionType(
          [],
          [],
          TupleType(
            [])))
      """
        )
    }

    public func test29() {
        let q = #quote(1...10)
        assertStructure(
            q,
            """
      Binary(
        IntegerLiteral(
          1,
          TypeName("Int", "s:Si")),
        Name(
          "...",
          "s:SLsE3zzzoiySNyxGx_xtFZ",
          FunctionType(
            [],
            [TypeName("Int", "s:Si"),
            TypeName("Int", "s:Si")],
            SpecializedType(
              TypeName("ClosedRange", "s:SN"),
              [TypeName("Int", "s:Si")]))),
        IntegerLiteral(
          10,
          TypeName("Int", "s:Si")),
        SpecializedType(
          TypeName("ClosedRange", "s:SN"),
          [TypeName("Int", "s:Si")]))
      """
        )
    }

    public func test30() {
        let x = 42
        blackHole(x)
        let q = #quote(Float(x))
        assertStructure(
            q,
            """
      Call(
        Name(
          "Float",
          "s:SfySfSicfc",
          FunctionType(
            [],
            [TypeName("Int", "s:Si")],
            TypeName("Float", "s:Sf"))),
        [nil],
        [Name(
          "x",
          "<unstable USR>",
          TypeName("Int", "s:Si"))],
        TypeName("Float", "s:Sf"))
      """
        )
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
