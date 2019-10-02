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

struct BitcodeRecord {
    var code: Bits
    var ops: [BitcodeOperand]
}

indirect enum OperandKind {
    case literal(Bits)
    case fixed(width: Int)
    case vbr(width: Int)
    case array(OperandKind)
    case char6
    case blob
}

indirect enum BitcodeOperand {
    case bits(Bits)
    case blob([UInt8])
    case array([BitcodeOperand])

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

    func name(of record: BitcodeRecord) -> String? {
        return info.recordNames[record.code]
    }
}
