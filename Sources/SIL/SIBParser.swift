import Foundation

let SIB_MAGIC: [UInt8] = [0xE2, 0x9C, 0xA8, 0x0E]

enum SIBFileError: Error {
  case cannotOpenFile
  case incorrectMagic
}

enum SIBError: Error {
  case parseError(_ reason: String)
  case unsupported(_ what: String)
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

fileprivate func expectOne<T>(called name: String, among candidates: [T]) throws -> T {
  guard candidates.count == 1 else {
    throw SIBError.parseError("Couldn't find a representative " + name)
  }
  return candidates[0]
}

fileprivate func findBlock(called name: String, in block: BitcodeBlock) throws -> BitcodeBlock {
  let candidates = block.subblocks.filter { $0.info.name == name }
  return try expectOne(called: name, among: candidates)
}

fileprivate func findRecord(called name: String, in block: BitcodeBlock) throws -> BitcodeRecord {
  let candidates = block.records.filter { block.name(of: $0) == name }
  return try expectOne(called: name, among: candidates)
}

// SIB files are designed for quick function lookups, so instead of storing
// the function names along their definitions in the SIL block, the only place
// where they're stored is in the SIL block index, where you can use them to
// look up their offsets in the bitcode file. To make matters worse, they are
// stored inside a binary blob containing an on-disk LLVM hash map, which is
// what we parse inside this method.
func parseNameIndexRecord(_ record: BitcodeRecord) throws -> [Bits] {
  guard record.ops.count == 2 else {
    throw SIBError.parseError("Expected two operands to the index record")
  }
  guard case let .bits(tableOffsetBits) = record.ops[0] else {
    throw SIBError.parseError("Expected the index table offset to be encoded as a simple value")
  }
  guard case let .blob(tableData) = record.ops[1] else {
    throw SIBError.parseError("Expected the index table data to be encoded as a binary blob")
  }

  func readLittleUInt(_ width: Int, at offset: inout Int) -> Int {
    let bytes = width / 8
    assert(width % 8 == 0)
    assert(bytes <= (Int.bitWidth / 8))
    let arr = tableData[offset..<offset + bytes]
    var result: UInt64 = 0
    for byte in arr.reversed() {
      result = result << 8
      result |= UInt64(byte)
    }
    offset += bytes
    return Int(result)
  }

  func parseBucket(_ startOffset: Int) -> [(id: Int, name: Bits)] {
    var bucketOffset = startOffset
    // NB: Bucket offset of 0 means that it is empty
    guard bucketOffset != 0 else { return [] }
    let numEntries = readLittleUInt(16, at: &bucketOffset)
    return (0..<numEntries).map { _ in
      bucketOffset += 4  // Skip the key hash
      let key = readLittleUInt(32, at: &bucketOffset)
      let value = readLittleUInt(32, at: &bucketOffset)
      return (id: value, name: Bits(key))
    }
  }

  // The first operand of this node gives us an offset into the binary blob
  // where we can find the descriptor of the hash map structure.
  var tableOffset = tableOffsetBits.asInt()
  let numBuckets = readLittleUInt(32, at: &tableOffset)
  let numEntries = readLittleUInt(32, at: &tableOffset)
  // Number of buckets and entries is followed by an offset for each bucket.
  var reverseMap = (0..<numBuckets).flatMap { _ in
    parseBucket(readLittleUInt(32, at: &tableOffset))
  }
  // Also, the map is unordered, so we have to fix this.
  reverseMap.sort(by: { $0.id < $1.id })

  assert(reverseMap.map({ $0.id }) == Array(1...numEntries))
  return reverseMap.map { $0.name }
}

struct PeekingIterator<T : IteratorProtocol> : IteratorProtocol {
  typealias Element = T.Element
  var current: Element?
  var it: T

  init(_ it: T) {
    self.it = it
  }

  mutating func next() -> Element? {
    if let value = current {
      current = nil
      return value
    } else {
      return it.next()
    }
  }

  mutating func peek() -> Element? {
    current = current ?? it.next()
    return current
  }

  mutating func next(if f: (Element) -> Bool) -> Element? {
    guard let element = peek() else { return nil }
    return f(element) ? next() : nil
  }
}

fileprivate func getFlag(_ op: BitcodeOperand) throws -> Bits {
  guard case let .bits(value) = op else {
    throw SIBError.parseError("Expected a flag to be encoded using bits")
  }
  return value
}

class SIBParser {
  let moduleBlock: BitcodeBlock
  let SILBlock: BitcodeBlock
  // XXX: Don't access this directly -- use identifier(_:) instead!
  let _identifiers: [String]
  // XXX: The only reason why this thing is an implicitly unwrapped var is that
  // I can't use self.identifier(:_) to get the function names otherwise, because
  // Swift complains that the instance has not finished initializing yet.
  var functionNames: Array<String>.Iterator!
  var records: PeekingIterator<Array<BitcodeRecord>.Iterator>!

  class DeclsAndTypesParser {
    let block: BitcodeBlock
    let identResolver: (Bits) -> String
    var records: PeekingIterator<Array<BitcodeRecord>.Iterator>

    init(_ block: BitcodeBlock, _ resolver: @escaping (Bits) -> String) throws {
      guard block.info.name == "DECLS_AND_TYPES_BLOCK" else {
        throw SIBError.parseError("Expected the decls and types block to be called DECLS_AND_TYPES_BLOCK")
      }
      self.block = block
      self.identResolver = resolver
      self.records = PeekingIterator(block.records.makeIterator())
    }

    func parseXRef(length: Int) throws {
      var name = ""
      for _ in 0..<length {
        guard let component = records.next() else {
          throw SIBError.parseError("Run out of records before the end of XRef")
        }
        let componentName: BitcodeOperand
        switch block.name(of: component) {
        case "XREF_TYPE_PATH_PIECE": componentName = component.ops[0]
        case "XREF_VALUE_PATH_PIECE": componentName = component.ops[1]
        default:
          fatalError("Unhandled XRef type: " + (block.name(of: component) ?? "<unknown name>"))
        }
        if !name.isEmpty {
          name += "."
        }
        name += identResolver(component.ops[0].bits!)
      }
      print(name)
    }

    func parse() throws {
      /*var types: [Int: Type] = [:]*/
      while let record = records.next() {
        let ops = record.ops
        print(block.name(of: record) ?? "unknown name")
        switch block.name(of: record) {
        case "NOMINAL_TYPE":
          // NB: Parents are important. For example, the Element in Dictionary<String, Int>.Element
          //     will be a nominal type with Dictionary<String, Int> as a parent.
          let declRef = ops[0]
          let parentRef = ops[1]
        case "SIL_FUNCTION_TYPE":
          let hasErrorResult = try getFlag(ops[5])
          let numParameters = ops[6]
          let numYields = ops[7]
          let numResults = ops[8]
          let genericSignatureRef = ops[9]
          let signatureData = ops[10]
          print("Function type with " + String(numParameters.bits!.asInt()) + " inputs and " + String(numResults.bits!.asInt()) + " results")
        case "BOUND_GENERIC_TYPE":
          break
        case "BUILTIN_ALIAS_TYPE":
          break
        case "XREF":
          // ops[0] is the module name
          try parseXRef(length: ops[1].bits!.asInt())
          break
        case "FUNC_DECL":
          break
        case "PARAMETERLIST":
          break
        case "LOCAL_DISCRIMINATOR":
          break
        case "PARAM_DECL":
          break
        case "DECL_CONTEXT":
          break
        default:
          throw SIBError.unsupported("type record: " + (block.name(of: record) ?? "<unknown record>"))
        }
      }
    }
  }

  init(moduleBlock: BitcodeBlock) throws {
    self.moduleBlock = moduleBlock
    guard moduleBlock.info.name == "MODULE_BLOCK" else {
      throw SIBError.parseError("Expected a MODULE_BLOCK")
    }
    self.SILBlock = try findBlock(called: "SIL_BLOCK", in: moduleBlock)
    records = PeekingIterator(SILBlock.records.makeIterator())

    let identifierRecord = try findRecord(
      called: "IDENTIFIER_DATA",
      in: findBlock(
        called: "IDENTIFIER_DATA_BLOCK",
        in: moduleBlock))
    let identifierOffRecord = try findRecord(
      called: "IDENTIFIER_OFFSETS",
      in: findBlock(
        called: "INDEX_BLOCK",
        in: moduleBlock))
    guard identifierRecord.ops.count == 1 else {
      throw SIBError.parseError("Expected only the identifier blob in the identifier data record")
    }
    guard case let .blob(identifierData) = identifierRecord.ops[0] else {
      throw SIBError.parseError("Expected identifier data operand to be a blob")
    }
    guard identifierOffRecord.ops.count == 1 else {
      throw SIBError.parseError("Expected only one operand to the identifier offset record")
    }
    guard case let .array(identifierOffsets) = identifierOffRecord.ops[0] else {
      throw SIBError.parseError("Expected the identifier offset record operand to be an array")
    }
    _identifiers = try identifierOffsets.map { offset in
      guard let offsetBits = offset.bits else {
        throw SIBError.parseError("Expected identifier offset to be encoded as a regular value")
      }
      let suffix = identifierData.suffix(from: offsetBits.asInt())
      return String(bytes: suffix.prefix(upTo: suffix.firstIndex(of: 0)!), encoding: .utf8)!
    }
    print(_identifiers)

    let funcNamesRecord = try findRecord(
      called: "SIL_FUNC_NAMES",
      in: findBlock(
        called: "SIL_INDEX_BLOCK",
        in: moduleBlock))
    functionNames = try parseNameIndexRecord(funcNamesRecord).map(identifier).makeIterator()

    let typesBlock = try findBlock(called: "DECLS_AND_TYPES_BLOCK", in: moduleBlock)
    try DeclsAndTypesParser(typesBlock, self.identifier).parse()
  }

  func identifier(_ idBits: Bits) -> String {
    let NUM_SPECIAL_IDS = 6
    let id = idBits.asInt()
    guard id >= NUM_SPECIAL_IDS else {
      // I was too lazy to make this throwing and keep adding try everywhere
      // If someone hits this there's really not much we can do
      fatalError("Special identifiers are not supported yet")
    }
    return _identifiers[id - NUM_SPECIAL_IDS]
  }

  func parse() throws -> Module {
    var functions: [Function] = []
    while let record = records.next() {
      guard let name = SILBlock.name(of: record) else {
        throw SIBError.parseError("Unknown record name")
      }
      switch name {
      case "SIL_FUNCTION":
        functions.append(try parseFunctionRecord(record.ops))
      default:
        fatalError("Unexpected record: " + (SILBlock.name(of: record) ?? "<unknown name>"))
      }
    }
    return Module(functions)
  }

  func isTopLevelDecl(_ record: BitcodeRecord) -> Bool {
    switch SILBlock.name(of: record) {
    case "SIL_FUNCTION": return true
    case "SIL_VTABLE": return true
    case "SIL_GLOBALVAR": return true
    case "SIL_WITNESS_TABLE": return true
    default: return false
    }
  }

  func isBlockRecord(_ record: BitcodeRecord) -> Bool {
    return SILBlock.name(of: record) == "SIL_BASIC_BLOCK"
  }

  func parseFunctionRecord(_ ops: [BitcodeOperand]) throws -> Function {
    guard ops.count == 18 else {
      throw SIBError.parseError("Expected 18 operands to SIL_FUNCTION")
    }
    var attributes: [FunctionAttribute] = []
    let linkage = try getLinkage(ops[0])
    if try !getFlag(ops[1]).isZero { attributes.append(.transparent) }
    if try !getFlag(ops[2]).isZero { attributes.append(.serialized) }
    if try !getFlag(ops[3]).isZero { attributes.append(.thunk) }
    // TODO: Do we need to handle isWithoutActuallyEscapingThunk?
    // TODO: Do we need to hanlde isGlobalInit?
    switch try getFlag(ops[6]) {
    case 0:  // InlineDefault
      break
    case 1:  // NoInline
      attributes.append(.noInline)
    case 2:  // AlwaysInline
      attributes.append(.alwaysInline)
    default:
      throw SIBError.parseError("Unknown inline type")
    }
    // TODO: Do we need to handle optimization mode?
    // TODO: Do we need to handle effects kind?
    // XXX: We ignore specialization attributes for now
    // TODO: Do we need to handle hasOwnership?
    // TODO: Do we need isWeakLinked?
    if try !getFlag(ops[12]).isZero { attributes.append(.dynamicallyReplacable) }
    // TODO: Do we need function id?
    // TODO: Do we need replaced function id?
    // TODO: Do we need the generic env?
    // TODO: Do we need clangNodeOwnerID?
    guard case let .array(semantics) = ops[17] else {
      throw SIBError.parseError("Expected function semantics to be an array")
    }
    for s in semantics {
      guard case let .bits(nameIdx) = s else {
        throw SIBError.parseError(
          "Expected function semantics annotations to be encoded using simple values")
      }
      attributes.append(.semantics(identifier(nameIdx)))
    }

    guard let name = functionNames.next() else {
      throw SIBError.parseError("Ran out of function names")
    }
    var blocks: [Block] = []
    while let record = records.peek(), isBlockRecord(record) {
      blocks.append(parseBlock())
    }
    let type: Type = .selfType  // TODO: get the function type
    return Function(linkage, attributes, name, type, blocks)
  }

  func parseBlock() -> Block {
    let isBlockBody = { !self.isTopLevelDecl($0) && !self.isBlockRecord($0) }
    let blockRecord = records.next()
    while let record = records.next(if: isBlockBody) {
      print(SILBlock.name(of: record)!)
    }
    return Block("", [], [])
  }

  func getLinkage(_ op: BitcodeOperand) throws -> Linkage {
    switch op.bits {
    case 0: return .public
    case 1: return .publicNonABI
    case 2: return .hidden
    case 3: return .shared
    case 4: return .private
    case 5: return .publicExternal
    case 6: return .hiddenExternal
    case 7: return .sharedExternal
    case 8: return .privateExternal
    default: throw SIBError.parseError("Unknown linkage kind")
    }
  }
}
