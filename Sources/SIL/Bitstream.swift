import Foundation

// You can think of this struct as either [Bool] representing a bit sequence
// or as an arbitrary precision integer (with checked casts to fixed-width values).
struct Bits: Equatable, Hashable, ExpressibleByIntegerLiteral, CustomStringConvertible {
    // Sorted in the order of significance, i.e. bits[0] is the LSB.
    private var bits: [Bool]
    var description: String { String(bits.reversed().map { $0 ? "1" : "0" }) }
    var count: Int { bits.lastIndex(of: true).map { $0 + 1 } ?? 0 }
    var isZero: Bool { bits.allSatisfy { !$0 } }

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

    // TODO(#30): Going through strings might be a bit slow, and in those cases
    //            we can utilize bitwise shifts, or use a more efficient representation
    func asUInt8() -> UInt8 { return cast() }
    func asUInt32() -> UInt32 { return cast() }
    func asInt() -> Int {
        assert(
            count <= Int.bitWidth - 1,
            "Casting a bit sequence of length " + String(bits.count) + " to an integer of width "
                + String(Int.bitWidth - 1))
        return Int(asUInt32())
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
            return try next(bits: 8).asUInt8()
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
