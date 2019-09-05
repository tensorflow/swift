// This is a temporary addition to libSIL and will likely be removed in the future.
// It is a hack that allows one to read the output of e.g. swiftc -dump-ast.
public enum SExpr : Equatable {
    public enum Property : Equatable {
      case value(SExpr)
      case field(String, SExpr)
    }

    case symbol(String)
    case string(String)
    case sourceRange(String) // We don't parse those further right now
    case record(String, [Property])

    public static func parse(fromPath path: String) throws -> SExpr {
        let parser = try SExprParser(forPath: path)
        return try parser.parseExpr()
    }
}

class SExprParser: Parser {
    func parseExpr() throws -> SExpr {
        if skip("(") {
            var properties: [SExpr.Property] = []
            guard case let .symbol(name) = try parseExpr() else {
                throw parseError("Expected an expression body to start with a symbol")
            }
            while !skip(")") {
                let expr = try parseExpr()
                if case let .symbol(propName) = expr, skip("=") {
                    properties.append(.field(propName, try parseValue()))
                } else {
                    if case let .symbol(exprValue) = expr {
                        guard !exprValue.isEmpty else {
                            throw parseError("An empty property?")
                        }
                    }
                    properties.append(.value(expr))
                }
            }
            return .record(name, properties)
        }
        return try parseValue()
    }

    func parseValue() throws -> SExpr {
        if skip("'") {
            let result = take(while: { $0 != "'" })
            try take("'")
            return .string(result)
        }
        if skip("\"") {
            let result = take(while: { $0 != "\"" })
            try take("\"")
            return .string(result)
        }
        if skip("[") {
            let result = take(while: { $0 != "]" })
            try take("]")
            return .sourceRange(result)
        }
        return try parseSymbol()
    }

    func parseSymbol() throws -> SExpr {
        // NB: This is more complicated than it ever should be because swiftc
        //     likes to print badly formed symbols that look like Module.(file).Type
        var result = ""
        while true {
            let c = peek()
            if !c.isWhitespace && !"()=".contains(c) {
                let cs = String(c)
                try take(cs, keepingTrivia: true)
                result += cs
                continue
            }
            if c == "(", skip("(file)") {
                result += "(file)"
                continue
            }
            break
        }
        skipTrivia()
        return .symbol(result)
    }
}

class SExprPrinter: Printer {
    func printExpr(_ e: SExpr) {
        switch e {
        case let .symbol(value): print(value)
        case let .string(value): print("'\(value)'")
        case let .sourceRange(value): print("[\(value)]")
        case let .record(name, properties):
            print("(")
            print(name)
            for prop in properties {
                switch prop {
                case let .value(value):
                  if case .record(_, _) = value {
                    print("\n")
                    indent()
                    printExpr(value)
                    unindent()
                  } else {
                    print(" ")
                    printExpr(value)
                  }
                case let .field(name, value):
                  print(" ")
                  print(name)
                  print("=")
                  printExpr(value)
                }
            }
            print(")")
        }
    }
}

extension SExpr: CustomStringConvertible {
    public var description: String {
        let printer = SExprPrinter()
        printer.printExpr(self)
        return printer.description
    }
}
