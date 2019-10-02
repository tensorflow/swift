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

// I'm accustomed to writing token-based parsers, but this time I needed to hack something up
// real quick, so I decided to skip writing the tokenizer. Surprisingly, the result ended up being
// quite decent.
//
// Just like in token-based parsers, we take apart a program using high-level methods that
// manipulate parsing state that includes an array of characters and a cursor. Parsing state is
// never accessible outside of this base class to ensure code quality.
//
// However, unlike in token-based parsers, there isn't a well-defined separation of the program
// into atoms. There are facilities to consume ranges of text starting from cursor, there is a
// facility to skip trivia (whitespaces and comments), but it's the responsibility of the parser
// to make sure that underlying fragments of text are properly separated.
//
// Outside of this caveat, which hasn't been a problem for parsing SIL, this infrastructure seems
// to work well, providing a concise way to write a recursive descent parser. See SilParser.swift
// for examples.
class Parser {
    private let path: String
    private let chars: [Character]
    private var cursor: Int = 0  // first character in chars that we haven't parsed yet
    var position: Int { return cursor }

    init(forPath path: String) throws {
        self.path = path
        guard let data = FileManager.default.contents(atPath: path) else {
            throw Parser.Error(path, "file not found")
        }
        guard let text = String(data: data, encoding: .utf8) else {
            throw Parser.Error(path, "file not UTF-8 encoded")
        }
        self.chars = Array(text)
        skipTrivia()
    }

    init(forString s: String) {
        self.path = "<memory>"
        self.chars = Array(s)
        skipTrivia()
    }

    // MARK: "Token"-level APIs

    /// Check whether chars[cursor..] starts with a given string.
    func peek(_ query: String) -> Bool {
        assert(!query.isEmpty)
        return chars.suffix(from: cursor).starts(with: Array(query))
    }

    /// If chars[cursor..] starts with a given string, consume string and skip trivia afterwards.
    /// Otherwise, raise a parse error.
    func take(_ query: String) throws {
        guard peek(query) else { throw parseError("\(query) expected") }
        cursor += query.count
        skipTrivia()
    }

    /// If chars[cursor..-1] starts with a given string, consume string, skip trivia and return true.
    /// Otherwise, return false.
    func skip(_ query: String) -> Bool {
        // TODO(#13): Deduplicate with respect to take.
        guard peek(query) else { return false }
        cursor += query.count
        skipTrivia()
        return true
    }

    /// Consume characters starting from cursor while a given predicate keeps being true and
    /// return the consumed string. Skip trivia afterwards.
    func take(while fn: (Character) -> Bool) -> String {
        let result = chars.suffix(from: cursor).prefix(while: fn)
        cursor += result.count
        skipTrivia()
        return String(result)
    }

    /// Consume characters starting from cursor while a given predicate keeps being true and
    /// report whether something was consumed. Skip trivia afterwards.
    func skip(while fn: (Character) -> Bool) -> Bool {
        let result = take(while: fn)
        return !result.isEmpty
    }

    /// If cursor points to whitespace or comment, consume until it doesn't.
    /// This provides a cheap way to make whitespace and comments insignificant.
    private func skipTrivia() {
        guard cursor < chars.count else { return }
        if chars[cursor].isWhitespace {
            cursor += 1
            skipTrivia()
        } else if skip("//") {
            while cursor < chars.count && chars[cursor] != "\n" {
                cursor += 1
            }
            skipTrivia()
        }
    }

    // MARK: Tree-level APIs

    // Applies the function, but restores the cursor from before the call if it returns nil.
    func maybeParse<T>(_ f: () throws -> T?) rethrows -> T? {
      let savedCursor = cursor
      if let result = try f() {
        return result
      } else {
        cursor = savedCursor
        return nil
      }
    }

    /// Same as `parseMany` but returning `nil` if the cursor isn't pointing at `pre`.
    /// This is necessary to e.g. accommodate a situation when not having a parameter list is
    /// as valid as having an empty parameter list.
    func parseNilOrMany<T>(
        _ pre: String, _ sep: String, _ suf: String, _ parseOne: () throws -> T
    ) throws -> [T]? {
        guard peek(pre) else { return nil }
        return try parseMany(pre, sep, suf, parseOne)
    }

    /// Run a given parser multiple times as follows:
    ///   1) Consume `pre`.
    ///   2) Run parser interleaved with consuming `sep`.
    ///   3) Consume `suf`.
    ///
    /// For example, we can parse `(x, y, ...)` via `parseMany("(", ",", ")") { parseElement() }`.
    func parseMany<T>(
        _ pre: String, _ sep: String, _ suf: String, _ parseOne: () throws -> T
    ) throws -> [T] {
        try take(pre)
        var result = [T]()
        if !peek(suf) {
            while true {
                let element = try parseOne()
                result.append(element)
                guard !peek(suf) else { break }
                guard !sep.isEmpty else { continue }
                try take(sep)
            }
        }
        try take(suf)
        return result
    }

    /// Same as `parseMany` but returning `nil` if the cursor isn't pointing at `pre`.
    /// If cursor isn't pointing at `pre`, return nil. This is necessary to e.g. accommodate
    /// a situation when not having attributes is valid.
    func parseNilOrMany<T>(_ pre: String, _ parseOne: () throws -> T) throws -> [T]? {
        guard peek(pre) else { return nil }
        return try parseMany(pre, parseOne)
    }

    func parseUntilNil<T>(_ parseOne: () throws -> T?) rethrows -> [T] {
      var result = [T]()
      while let element = try parseOne() {
        result.append(element)
      }
      return result
    }

    /// Run a given parser multiple times as follows:
    ///   1) Check that cursor if pointing at `pre` without consuming `pre`.
    ///   2) Run parser, repeat.
    ///
    /// For example, we can parse `@foo @bar` via `parseMany("@") { parseAttribute() }`.
    func parseMany<T>(_ pre: String, _ parseOne: () throws -> T) throws -> [T] {
        var result = [T]()
        repeat {
            let element = try parseOne()
            result.append(element)
        } while peek(pre)
        return result
    }

    // MARK: Error reporting APIs

    /// Raise a parser error at a given position.
    func parseError(_ message: String, at: Int? = nil) -> Parser.Error {
        let position = at ?? cursor
        let newlines = chars.enumerated().prefix(position).filter({ $0.element == "\n" })
        let line = newlines.count + 1
        let column = position - (newlines.last?.offset ?? 0) + 1
        return Parser.Error(path, line, column, message)
    }

    class Error: Swift.Error, CustomStringConvertible {
        let path: String
        let line: Int?
        let column: Int?
        let message: String

        public init(_ path: String, _ message: String) {
            self.path = path
            self.line = nil
            self.column = nil
            self.message = message
        }

        public init(_ path: String, _ line: Int, _ column: Int, _ message: String) {
            self.path = path
            self.line = line
            self.column = column
            self.message = message
        }

        var description: String {
            guard let line = line else { return "\(path): \(message)" }
            guard let column = column else { return "\(path):\(line): \(message)" }
            return "\(path):\(line):\(column): \(message)"
        }
    }
}
