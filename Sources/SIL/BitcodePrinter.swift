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

// Output of this printer is heavily inspired by llvm-bcanalyzer -dump.
// It supports most of its syntax, except:
// 1. We don't try to reinterpret arrays as strings
// 2. We don't report abbreviation id used to encode a record
class BitcodePrinter: Printer {
    func print(_ bits: Bits) {
        if bits.count <= 32 {
            print(bits.uint32)
        } else {
            print("...")
        }
    }

    private func printBlockName(_ block: BitcodeBlock) {
        if let name = block.info.name {
            print(name)
        } else {
            print("blockid=")
            print(block.info.id)
        }
    }

    private func printOperand(_ op: BitcodeOperand, _ i: inout Int) {
        switch (op) {
        case let .bits(value):
            print(" op")
            print(i)
            print("=")
            print(value)
            i += 1
        case let .array(values):
            for v in values {
                printOperand(v, &i)
            }
        default:
            break
        }
    }

    func print(_ record: BitcodeRecord, in block: BitcodeBlock) {
        print("<")
        if let name = block.info.recordNames[record.code] {
            print(name)
        } else {
            print("code=")
            print(record.code)
        }
        var i: Int = 0
        for op in record.ops {
            printOperand(op, &i)
        }
        print("/>")
        if case let .some(.blob(value)) = record.ops.last {
            print(" blob data = ")
            if let asString = String(bytes: value, encoding: .utf8) {
                print("'")
                print(asString)
                print("'")
            } else {
                print("unprintable, ")
                print((value.count + 7) / 8)
                print(" bytes.")
            }
        }
        print("\n")
    }

    func print(_ block: BitcodeBlock) {
        // ID 0 is normally reserved for the info block, but we don't parse it
        // as a block anyway, and we use the 0 ID for the main outer block instead
        if block.info.id != 0 {
            print("<")
            printBlockName(block)
            print(" NumWords=")
            print(block.blockLen32)
            print(" BlockCodeSize=")
            print(block.abbrLen)
            print(">\n")
            indent()
        }
        for record in block.records {
            print(record, in: block)
        }
        for subblock in block.subblocks {
            print(subblock)
        }
        if block.info.id != 0 {
            unindent()
            print("</")
            printBlockName(block)
            print(">\n")
        }
    }
}
