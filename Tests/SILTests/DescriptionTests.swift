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
import SIL

public final class DescriptionTests: XCTestCase {
    public func testIdentity() {
        let block = Block(
            "bb0",
            [Argument("%0", .namedType("Int"))],
            [],
            TerminatorDef(.return(Operand("%0", .namedType("Int"))), nil)
        )
        let identity = Function(
            .public,
            [],
            "$s4main8identityyS2iF",
            .attributedType(
                [.convention(.thin)],
                .functionType([.namedType("Int")], .namedType("Int"))),
            [block])
        let module = Module([identity])
        XCTAssertEqual(
            module.description,
            """
      sil @$s4main8identityyS2iF : $@convention(thin) (Int) -> Int {
      bb0(%0 : $Int):
        return %0 : $Int
      }
      """
        )
    }

    public func testAdd() {
        let block = Block(
            "bb0",
            [Argument("%0", .namedType("Int")), Argument("%1", .namedType("Int"))],
            [
                OperatorDef(
                    Result(["%4"]),
                    .structExtract(
                        Operand("%0", .namedType("Int")), DeclRef(["Int", "_value"], nil, nil)),
                    nil),
                OperatorDef(
                    Result(["%5"]),
                    .structExtract(
                        Operand("%1", .namedType("Int")), DeclRef(["Int", "_value"], nil, nil)),
                    nil),
                OperatorDef(
                    Result(["%6"]),
                    .integerLiteral(.namedType("Builtin.Int1"), -1),
                    nil),
                OperatorDef(
                    Result(["%7"]),
                    .builtin(
                        "sadd_with_overflow_Int64",
                        [
                            Operand("%4", .namedType("Builtin.Int64")),
                            Operand("%5", .namedType("Builtin.Int64")),
                            Operand("%6", .namedType("Builtin.Int1"))
                        ],
                        .tupleType([.namedType("Builtin.Int64"), .namedType("Builtin.Int1")])),
                    nil),
                OperatorDef(
                    Result(["%8"]),
                    .tupleExtract(
                        Operand(
                            "%7",
                            .tupleType([.namedType("Builtin.Int64"), .namedType("Builtin.Int1")])),
                        0),
                    nil),
                OperatorDef(
                    Result(["%9"]),
                    .tupleExtract(
                        Operand(
                            "%7",
                            .tupleType([.namedType("Builtin.Int64"), .namedType("Builtin.Int1")])),
                        1),
                    nil),
                OperatorDef(
                    nil,
                    .condFail(Operand("%9", .namedType("Builtin.Int1")), ""),
                    nil),
                OperatorDef(
                    Result(["%11"]),
                    .struct(.namedType("Int"), [Operand("%8", .namedType("Builtin.Int64"))]),
                    nil),
            ],
            TerminatorDef(.return(Operand("%11", .namedType("Int"))), nil)
        )
        let add = Function(
            .public,
            [],
            "$s4main3addyS2i_SitF",
            .attributedType(
                [.convention(.thin)],
                .functionType([.namedType("Int"), .namedType("Int")], .namedType("Int"))),
            [block])
        let module = Module([add])
        XCTAssertEqual(
            module.description,
            """
      sil @$s4main3addyS2i_SitF : $@convention(thin) (Int, Int) -> Int {
      bb0(%0 : $Int, %1 : $Int):
        %4 = struct_extract %0 : $Int, #Int._value
        %5 = struct_extract %1 : $Int, #Int._value
        %6 = integer_literal $Builtin.Int1, -1
        %7 = builtin "sadd_with_overflow_Int64"(%4 : $Builtin.Int64, %5 : $Builtin.Int64, %6 : $Builtin.Int1) : $(Builtin.Int64, Builtin.Int1)
        %8 = tuple_extract %7 : $(Builtin.Int64, Builtin.Int1), 0
        %9 = tuple_extract %7 : $(Builtin.Int64, Builtin.Int1), 1
        cond_fail %9 : $Builtin.Int1, ""
        %11 = struct $Int (%8 : $Builtin.Int64)
        return %11 : $Int
      }
      """
        )
    }
}

extension DescriptionTests {
    public static let allTests = [
        ("testIdentity", testIdentity),
        ("testAdd", testAdd),
    ]
}
