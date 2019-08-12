import Foundation
import Quote
import XCTest

func assertDescription(
  _ tree: Tree, _ expected: String, file: StaticString = #file, line: UInt = #line
) {
  XCTAssertEqual(tree.description, expected, file: file, line: line)
}

func assertDescription<T>(
  _ quote: Quote<T>, _ expected: String, file: StaticString = #file, line: UInt = #line
) {
  XCTAssertEqual(quote.description, expected, file: file, line: line)
}

func assertStructure(
  _ tree: Tree, _ expected: String, file: StaticString = #file, line: UInt = #line
) {
  XCTAssertEqual(stripUnstableUSRs(tree.structure), expected, file: file, line: line)
}

func assertStructure<T>(
  _ quote: Quote<T>, _ expected: String, file: StaticString = #file, line: UInt = #line
) {
  XCTAssertEqual(stripUnstableUSRs(quote.structure), expected, file: file, line: line)
}

private func stripUnstableUSRs(_ s: String) -> String {
  let range = NSRange(location: 0, length: s.count)
  let regex = try! NSRegularExpression(pattern: "\"s:10QuoteTests.*?\"", options: .caseInsensitive)
  let template = "\"<unstable USR>\""
  return regex.stringByReplacingMatches(in: s, options: [], range: range, withTemplate: template)
}
