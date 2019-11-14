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

    func print<T: CustomStringConvertible>(when: Bool = true, _ i: T) {
        print(when: when, i.description)
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

    func print<S: Collection>(_ xs: S, _ fn: (S.Element) -> Void) {
      for x in xs {
        fn(x)
      }
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

    func literal(_ b: Bool) {
        print(String(b))
    }

    func literal(_ f: Float) {
        print(String(f))
    }

    func literal(_ n: Int) {
        print(String(n))
    }

    func hex(_ n: Int) {
        print("0x" + String(format: "%X", n))
    }

    func literal(_ s: String) {
        // TODO(#24): Print string literals with control characters in a useful way.
        print("\"")
        print(s)
        print("\"")
    }
}
