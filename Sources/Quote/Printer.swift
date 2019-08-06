class Printer: CustomStringConvertible {
  var description: String = ""
  private var indentation: String = ""
  private var indented: Bool = false

  func indent() {
    let count = indentation.count + 2
    indentation = String(repeating: " ", count: count)
  }

  func unindent() {
    let count = max(indentation.count - 2, 0)
    indentation = String(repeating: " ", count: count)
  }

  func print<T: CustomStringConvertible>(when: Bool = true, _ x: T) {
    print(when: when, x.description)
  }

  func print(when: Bool = true, _ s: String) {
    guard when else { return }
    let lines = s.split(omittingEmptySubsequences: false) { $0.isNewline }
    for (i, line) in lines.enumerated() {
      if !indented && !line.isEmpty {
        description += indentation
        indented = true
      }
      description += line
      if i < lines.count - 1 {
        description += "\n"
        indented = false
      }
    }
  }

  func print<T>(_ x: T?, _ fn: (T) -> Void) {
    guard let x = x else { return }
    fn(x)
  }

  func print<T>(_ pre: String, _ x: T?, _ fn: (T) -> Void) {
    guard let x = x else { return }
    print(pre)
    fn(x)
  }

  func print<T>(_ x: T?, _ suf: String, _ fn: (T) -> Void) {
    guard let x = x else { return }
    fn(x)
    print(suf)
  }

  func print<S: Collection>(_ xs: S, _ sep: String, _ fn: (S.Element) -> Void) {
    var needSep = false
    for x in xs {
      if needSep {
        print(sep)
      }
      needSep = true
      fn(x)
    }
  }

  func print<S: Collection>(
    whenEmpty: Bool = true, _ pre: String, _ xs: S, _ sep: String, _ suf: String,
    _ fn: (S.Element) -> Void
  ) {
    guard !xs.isEmpty || whenEmpty else { return }
    print(pre)
    print(xs, sep, fn)
    print(suf)
  }

  func literal(_ s: String) {
    print("\"")
    print(s)
    print("\"")
  }

  func literal(_ s: String?) {
    if let s = s {
      literal(s)
    } else {
      print("nil")
    }
  }
}
