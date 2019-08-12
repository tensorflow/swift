struct BitcodeRecord {
    var code: Bits
    var ops: [BitcodeOperand]
}

indirect enum OperandKind {
    case literal(_ value: Bits)
    case fixed(_ width: Int)
    case vbr(_ width: Int)
    case array(_ element: OperandKind)
    case char6
    case blob
}

indirect enum BitcodeOperand {
    case bits(_ value: Bits)
    case blob(_ value: Bits)
    case array(_ values: [BitcodeOperand])

    var bits: Bits? {
        guard case let .bits(value) = self else { return nil }
        return value
    }
}

typealias Structure = [OperandKind]

class BitcodeBlockInfo {
    var id: Bits
    var name: String?
    var recordNames: [Bits: String] = [:]
    var abbreviations: [Bits: Structure] = [:]

    init(id: Bits) {
        self.id = id
    }
    // NB: This copies the structure, because all members are value types
    init(from other: BitcodeBlockInfo) {
        id = other.id
        name = other.name
        recordNames = other.recordNames
        abbreviations = other.abbreviations
    }
}

class BitcodeBlock {
    var info: BitcodeBlockInfo
    var records: [BitcodeRecord] = []
    var subblocks: [BitcodeBlock] = []
    let abbrLen: Int
    let blockLen32: Int

    convenience init(id: Bits, abbrLen: Int, blockLen32: Int) {
        self.init(info: BitcodeBlockInfo(id: id), abbrLen: abbrLen, blockLen32: blockLen32)
    }

    init(info: BitcodeBlockInfo, abbrLen: Int, blockLen32: Int) {
        self.info = info
        self.abbrLen = abbrLen
        self.blockLen32 = blockLen32
    }
}
