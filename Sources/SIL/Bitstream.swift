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

import Foundation

// You can think of this struct as either [Bool] representing a bit sequence
// or as an arbitrary precision integer (with checked casts to fixed-width values).
struct Bits: Equatable, Hashable, ExpressibleByIntegerLiteral, CustomStringConvertible {
    // Sorted in the order of significance, i.e. bits[0] is the LSB.
    private var bits: [Bool]
    var description: String { String(bits.reversed().map { $0 ? "1" : "0" }) }
    var count: Int { bits.lastIndex(of: true).map { $0 + 1 } ?? 0 }
    var isZero: Bool { bits.allSatisfy(!) }

    // TODO(#30): Going through strings might be a bit slow, and in those cases
    //            we can utilize bitwise shifts, or use a more efficient representation
    var uint8: UInt8 { return cast() }
    var uint32: UInt32 { return cast() }
    var int: Int {
        assert(
            count <= Int.bitWidth - 1,
            "Casting a bit sequence of length " + String(bits.count) + " to an integer of width "
                + String(Int.bitWidth - 1))
        return Int(uint32)
    }

    init(integerLiteral lit: Int) {
        self.init(lit)
    }

    init(_ value: Int) {
        self.bits = []
        var rem = value
        while rem != 0 {
            bits.append(rem % 2 == 1)
            rem /= 2
        }
    }

    init(leastFirst bits: [Bool]) { self.bits = bits }
    init(mostFirst bits: [Bool]) { self.bits = bits.reversed() }

    // NB: Assumes that the integer is unsigned!
    private func cast<T: FixedWidthInteger>() -> T {
        assert(
            count <= T.bitWidth,
            "Casting a bit sequence of length " + String(bits.count) + " to an integer of width "
                + String(T.bitWidth))
        return T.init(count == 0 ? "0" : description, radix: 2)!
    }

    static func join(_ arr: [Bits]) -> Bits {
        return Bits(leastFirst: Array(arr.map { $0.bits }.joined()))
    }

    static func == (lhs: Bits, rhs: Bits) -> Bool {
        let minLen = min(lhs.bits.count, rhs.bits.count)
        // NB: .count does not consider trailing zeros
        return zip(lhs.bits, rhs.bits).allSatisfy(==) && lhs.count <= minLen && rhs.count <= minLen
    }

    func hash(into hasher: inout Hasher) {
        for b in 0..<count {
            hasher.combine(b)
        }
    }
}

// Reinterprets Data as a stream of bits instead of bytes
struct Bitstream {
    let data: Data
    var offset: Int = 0  // NB: in bits, not bytes!
    var byteOffset: Int { offset / 8; }
    var bitOffset: Int { offset % 8; }
    var isEmpty: Bool { offset == data.count * 8 }

    enum Error: Swift.Error {
        case endOfFile
    }

    init(_ fromData: Data) { data = fromData }

    mutating func nextBit() throws -> Bool {
        try checkOffset(needBits: 1)
        let byte = data[byteOffset]
        let result = (byte >> bitOffset) % 2 == 1
        offset += 1
        return result
    }

    mutating func nextByte() throws -> UInt8 {
        if (offset % 8 == 0) {
            try checkOffset(needBits: 8)
            let result = data[byteOffset]
            offset += 8
            return result
        } else {
            return try next(bits: 8).uint8
        }
    }

    mutating func next(bits num: Int) throws -> Bits {
        var bits: [Bool] = []
        for _ in 0..<num {
            bits.append(try nextBit())
        }
        return Bits(leastFirst: bits)
    }

    mutating func next(bytes num: Int) throws -> [UInt8] {
        var bytes: [UInt8] = []
        for _ in 0..<num {
            bytes.append(try nextByte())
        }
        return bytes
    }

    mutating func align(toMultipleOf mult: Int) {
        let rem = offset % mult
        if rem == 0 { return }
        offset += mult - (offset % mult)
        assert(offset % mult == 0)
    }

    private func checkOffset(needBits needed: Int) throws {
        guard offset <= (data.count * 8 - needed) else {
            throw Error.endOfFile
        }
    }
}
