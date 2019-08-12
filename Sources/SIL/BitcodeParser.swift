import Foundation

class BitcodeParser {
    // Block ID: Default block info
    var blockInfoTemplates: [Bits: BitcodeBlockInfo] = [:]
    // NB: The choice of id is a bit questionable in here (0 is reserved for
    //     the info block), but I didn't feel like making the field optional.
    var blockStack: [BitcodeBlock] = [BitcodeBlock(id: 0, abbrLen: 2, blockLen32: 0)]
    var currentBlock: BitcodeBlock { blockStack.last! }
    var stream: Bitstream

    // Builtin abbreviation IDs
    let END_BLOCK: Bits = 0
    let ENTER_SUBBLOCK: Bits = 1
    let DEFINE_ABBREV: Bits = 2
    let UNABBREV_RECORD: Bits = 3

    // Builtin abbreviations within the info block
    let SETBID: Bits = 1
    let BLOCKNAME: Bits = 2
    let SETRECORDNAME: Bits = 3

    // Block ID of the info block
    let BLOCKINFO_ID: Bits = 0

    enum Error: Swift.Error {
        case unsupportedBlockInfoAbbrev(_ code: Bits)
        case unsupportedBlockInfoRecord(_ code: Bits)
        case unsupportedRecordId(_ operand: BitcodeOperand)
        case parseError(_ reason: String?)
    }

    init(_ stream: Bitstream) {
        self.stream = stream
    }

    func read(fixed width: Int) throws -> Bits {
        return try stream.next(bits: width)
    }

    func read(vbr width: Int) throws -> Bits {
        assert(width >= 1, "VBR fields cannot have a width smaller than 1")
        var chunks: [Bits] = []
        repeat {
            chunks.append(try stream.next(bits: width - 1))
        } while (try stream.next(bits: 1)) == 1
        return Bits.join(chunks)
    }

    func read(desc: OperandKind) throws -> BitcodeOperand {
        switch (desc) {
        case let .literal(v):
            return .bits(v)
        case let .fixed(w):
            return try .bits(read(fixed: w))
        case let .vbr(w):
            return try .bits(read(vbr: w))
        case let .array(elDesc):
            let length = try read(vbr: 6).asInt()
            return try .array((0..<length).map { _ in try read(desc: elDesc) })
        case .char6:
            fatalError("Char6 not supported")
        case .blob:
            let length = try read(vbr: 6).asInt()
            stream.align(toMultipleOf: 32)
            let result = try stream.next(bits: length * 8)
            stream.align(toMultipleOf: 32)
            return .blob(result)
        }
    }

    func parseUnabbrevRecord() throws -> BitcodeRecord {
        // [UNABBREV_RECORD, code(vbr6), numops(vbr6), op0(vbr6), op1(vbr6), ...]
        let code = try read(vbr: 6)
        let numOps = try read(vbr: 6)
        var ops: [BitcodeOperand] = []
        for _ in 1...numOps.asUInt32() {
            ops.append(try .bits(read(vbr: 6)))
        }
        return BitcodeRecord(code: code, ops: ops)
    }

    func parseFieldType() throws -> (result: OperandKind, complexity: Int) {
        let isLiteral = try read(fixed: 1)
        if isLiteral == 1 {
            return (result: .literal(try read(vbr: 8)), complexity: 1)
        }
        let encoding = try read(fixed: 3)
        let result: OperandKind
        switch (encoding.asUInt8()) {
        case 1:
            result = .fixed(try read(vbr: 5).asInt())
        case 2:
            result = .vbr(try read(vbr: 5).asInt())
        case 3:
            let (result:elementType, complexity:c) = try parseFieldType()
            return (result: .array(elementType), complexity: c + 1)
        case 4:
            result = .char6
        case 5:
            result = .blob
        default:
            throw Error.parseError("Unknown record field encoding: " + String(encoding.asUInt8()))
        }
        return (result: result, complexity: 1)
    }

    func parseAbbrevStructure() throws -> Structure {
        let numOps = try read(vbr: 5).asUInt32()
        var result: Structure = []
        var i = 0
        while i < numOps {
            let (result:r, complexity:c) = try parseFieldType()
            result.append(r)
            i += c
        }
        return result
    }

    func parseInfoBlock(abbrLen: Int) throws {
        var currentInfo: BitcodeBlockInfo?
        while true {
            let abbrev = try stream.next(bits: abbrLen)
            switch (abbrev) {
            case END_BLOCK:
                return
            case UNABBREV_RECORD:
                let record = try parseUnabbrevRecord()
                // Unabbreviated records have no structure, so the cast to bits is safe
                let ops = record.ops.map { $0.bits! }
                switch (record.code) {
                case SETBID:
                    assert(ops.count == 1)
                    let blockId: Bits = ops[0]
                    if blockInfoTemplates[blockId] == nil {
                        blockInfoTemplates[blockId] = BitcodeBlockInfo(id: blockId)
                    }
                    currentInfo = blockInfoTemplates[blockId]
                case BLOCKNAME:
                    let nameBytes = ops.map { $0.asUInt8() }
                    guard let name = String(bytes: nameBytes, encoding: .utf8) else {
                        // The name was incorrect, so we skip it.
                        continue
                    }
                    currentInfo?.name = name
                    break
                case SETRECORDNAME:
                    let recordId = ops[0]
                    let nameBytes = ops.suffix(from: 1).map { $0.asUInt8() }
                    guard let name = String(bytes: nameBytes, encoding: .utf8) else {
                        // The name was incorrect, so we skip it.
                        continue
                    }
                    currentInfo?.recordNames[recordId] = name
                    break
                default:
                    throw Error.unsupportedBlockInfoRecord(record.code)
                }
            default:
                throw Error.unsupportedBlockInfoAbbrev(abbrev)
            }
        }
    }

    func parseAbbrevRecord(_ structure: Structure) throws -> BitcodeRecord {
        assert(!structure.isEmpty)
        let codeOperand = try read(desc: structure[0])
        let ops = try structure.suffix(from: 1).map { try read(desc: $0) }
        // XXX: Ok, so here we make an assumption that the record code is not encoded
        //      using a blob or an array which I guess should be reasonable?
        guard let code = codeOperand.bits else {
            throw Error.unsupportedRecordId(codeOperand)
        }
        return BitcodeRecord(code: code, ops: ops)
    }

    func parse() throws -> BitcodeBlock {
        if stream.isEmpty {
            guard blockStack.count == 1 else {
                throw Error.parseError(
                    "End of stream encountered with some blocks still open")
            }
            return blockStack[0]
        }
        let abbrev = try stream.next(bits: currentBlock.abbrLen)
        switch (abbrev) {
        case END_BLOCK:
            // [END_BLOCK, <align32bits>]
            stream.align(toMultipleOf: 32)

            let _ = blockStack.popLast()
            guard !blockStack.isEmpty else {
                throw Error.parseError("Unexpected END_BLOCK")
            }

            return try parse()
        case ENTER_SUBBLOCK:
            // [ENTER_SUBBLOCK, blockid(vbr8), newabbrevlen(vbr4), <align32bits>, blocklen_32]
            let blockId = try read(vbr: 8)
            let newAbbrevLenBits = try read(vbr: 4)
            stream.align(toMultipleOf: 32)
            let blockLen32 = try Int(stream.next(bits: 32).asUInt32())

            let newAbbrevLen = newAbbrevLenBits.asInt()
            // BLOCKINFO block is a bit special and we'll reparse it
            // into blockInfoTemplates instead of having it as a subblock
            if (blockId == BLOCKINFO_ID) {
                try parseInfoBlock(abbrLen: newAbbrevLen)
            } else {
                var subblockInfo: BitcodeBlockInfo
                if let info = blockInfoTemplates[blockId] {
                    subblockInfo = BitcodeBlockInfo(from: info)
                } else {
                    subblockInfo = BitcodeBlockInfo(id: blockId)
                }
                let subblock = BitcodeBlock(
                    info: subblockInfo, abbrLen: newAbbrevLen, blockLen32: blockLen32)
                currentBlock.subblocks.append(subblock)
                blockStack.append(subblock)
                // XXX: At this point subblock is the currentBlock
            }

            return try parse()
        case DEFINE_ABBREV:
            // NB: Abbreviation IDs are assign in order of their declaration,
            //     but starting from 4 (because there are 4 builtin abbrevs).
            let abbrevId = Bits(currentBlock.info.abbreviations.count + 4)
            currentBlock.info.abbreviations[abbrevId] = try parseAbbrevStructure()

            return try parse()
        case UNABBREV_RECORD:
            currentBlock.records.append(try parseUnabbrevRecord())
            return try parse()
        default:  // Abbreviated record
            guard let structure = currentBlock.info.abbreviations[abbrev] else {
                throw Error.parseError("Undeclared abbreviation: " + abbrev.description)
            }
            let record = try parseAbbrevRecord(structure)
            currentBlock.records.append(record)
            return try parse()
        }
    }
}

let SIB_MAGIC: [UInt8] = [0xE2, 0x9C, 0xA8, 0x0E]

enum SIBFileError: Error {
    case cannotOpenFile
    case incorrectMagic
}

func loadSIBBitcode(fromPath path: String) throws -> BitcodeBlock {
    guard let handle = FileHandle(forReadingAtPath: path) else {
        throw SIBFileError.cannotOpenFile
    }

    var stream = Bitstream(handle.readDataToEndOfFile())
    if (try stream.next(bytes: 4) != SIB_MAGIC) {
        throw SIBFileError.incorrectMagic
    }

    let parser = BitcodeParser(stream)
    return try parser.parse()
}
