# Using Swift for TensorFlow

This document explains basic usage of Swift for TensorFlow, including:
* How to run Swift in Colaboratory
* How to run the Swift REPL
* How to use the Swift interpreter and compiler
* How to use Swift for TensorFlow with Xcode (**macOS only**)

To see example models written using Swift for TensorFlow, go to [tensorflow/swift-models](https://github.com/tensorflow/swift-models).

**Note:** Swift for TensorFlow is an early stage project. It has been released to enable open source development and is not yet ready for general use by machine learning developers.

## Colaboratory

[Colaboratory](https://colab.research.google.com) is a free [Jupyter](https://jupyter.org/) notebook environment that requires no setup and runs entirely in the cloud.

To launch Swift in Colab, just open [this blank Swift notebook](https://colab.research.google.com/github/tensorflow/swift/blob/master/notebooks/blank_swift.ipynb)!

Put Swift code in the cell, and click the play button on the left of the cell (or hit Ctrl + Enter) to execute it.

For examples of what you can do, visit [this tutorial](https://colab.research.google.com/github/tensorflow/swift/blob/master/docs/site/tutorials/model_training_walkthrough.ipynb) in Colab.

## REPL (Read Eval Print Loop)

You must have a working toolchain for Swift for TensorFlow (`swift`, `swiftc`, etc) before proceeding with these instructions. If not, please [install Swift for TensorFlow](Installation.md) or [build from source](https://github.com/apple/swift/blob/tensorflow/README.md) before proceeding.

An easy way to experiment with Swift is the Read Eval Print Loop, or REPL. To try it, open your terminal application and run `swift`.

You should see a prompt, similar to the following:

```console
Welcome to Swift version 4.2-dev (LLVM 04bdb56f3d, Clang b44dbbdf44). Type :help for assistance.
  1>
```

You can type Swift statements and the REPL will execute them immediately. Results are formatted nicely:

```console
  1> import TensorFlow
  2> var x = Tensor<Float>([[1, 2], [3, 4]])
x: TensorFlow.Tensor<Float> = [[1.0, 2.0], [3.0, 4.0]]
  3> x + x
$R0: TensorFlow.Tensor<Float> = [[2.0, 4.0], [6.0, 8.0]]
  4> for _ in 0..<3 {
  5.     x += x
  6. }
  7> x
$R1: TensorFlow.Tensor<Float> = [[8.0, 16.0], [24.0, 32.0]]
  8> x[0] + x[1]
$R2: TensorFlow.Tensor<Float> = [32.0, 48.0]
```

**Note:** using the `TensorFlow` module in the Swift REPL on macOS is known to
be problematic since Swift for TensorFlow 0.5.
[TF-940](https://bugs.swift.org/browse/TF-940) tracks this issue.

```console
$ swift
Welcome to Swift version 5.1-dev (LLVM 200186e28b, Swift 1238976565).
Type :help for assistance.
  1> import TensorFlow
  2> Tensor(1)
error: Couldn't lookup symbols:
  TensorFlow.TensorHandle.init(copyingFromCTensor: Swift.OpaquePointer) -> TensorFlow.TensorHandle<A>
  TensorFlow.TensorHandle.init(copyingFromCTensor: Swift.OpaquePointer) -> TensorFlow.TensorHandle<A>
```

## Interpreter

You must have a working toolchain for Swift for TensorFlow (`swift`, `swiftc`, etc) before proceeding with these instructions. If not, please [install Swift for TensorFlow](Installation.md) or [build from source](https://github.com/apple/swift/blob/tensorflow/README.md) before proceeding.

With the Swift interpreter, you can use Swift like a scripting language. Create a file called `inference.swift` with your favorite text editor and paste the following:

```swift
import TensorFlow

struct MLPClassifier {
    var w1 = Tensor<Float>(repeating: 0.1, shape: [2, 4])
    var w2 = Tensor<Float>(shape: [4, 1], scalars: [0.4, -0.5, -0.5, 0.4])
    var b1 = Tensor<Float>([0.2, -0.3, -0.3, 0.2])
    var b2 = Tensor<Float>([[0.4]])

    func prediction(for x: Tensor<Float>) -> Tensor<Float> {
        let o1 = tanh(matmul(x, w1) + b1)
        return tanh(matmul(o1, w2) + b2)
    }
}
let input = Tensor<Float>([[0.2, 0.8]])
let classifier = MLPClassifier()
let prediction = classifier.prediction(for: input)
print(prediction)
```

Save `inference.swift` and navigate to its containing directory in the terminal. Then, run `swift -O inference.swift`. You should see something like:

```console
$ swift -O inference.swift
[[0.680704]]
```

**Note:** the `-O` flag enables Swift to run with optimizations. This is currently required for some programs that use the `TensorFlow` module to run properly.  This will become unnecessary when the compiler implementation is completed. Check out the [FAQ](https://github.com/tensorflow/swift/blob/master/FAQ.md#why-do-i-get-error-array-input-is-not-a-constant-array-of-tensors) for more details.

The Swift interpreter ran your program and printed the classifier's prediction, as expected.

**Extra**: If your operating system supports multi-argument shebang lines, you can turn `inference.swift` into a directly-invokable script by adding the following line at the top of `inference.swift`:

* Mac: `#!/usr/bin/env swift -O`
* Ubuntu 16.04: `#!swift -O`

Next, add executable permissions to `inference.swift`:

```console
$ chmod +x inference.swift
```

You can now run `inference.swift` using `./inference.swift`:

```console
$ ./inference.swift
[[0.680704]]
```

If you get an error from running `./inference.swift` directly but not from `swift -O inference.swift`, it’s likely because your operating system doesn’t support multi-argument shebang lines.

## Compiler

You must have a working toolchain for Swift for TensorFlow (`swift`, `swiftc`, etc) before proceeding with these instructions. If not, please [install Swift for TensorFlow](Installation.md) or [build from source](https://github.com/apple/swift/blob/tensorflow/README.md) before proceeding.

With the Swift compiler, you can compile Swift programs into executable binaries. To try it, run the following:
* Mac: ``swiftc -O -sdk `xcrun --show-sdk-path` inference.swift``
* Ubuntu: `swiftc -O inference.swift`

`swiftc` should produce an executable in the current directory called `inference`. Run it to see the same result:

```console
$ ./inference
[[0.680704]]
```

This was a simple demonstration of Swift for TensorFlow. To see example models written using Swift for TensorFlow, go to [tensorflow/swift-models](https://github.com/tensorflow/swift-models).

## (Mac-only) Xcode

Swift for TensorFlow provides an Xcode toolchain. Begin by installing it from [this page](Installation.md).

Next, switch to the new toolchain. Open Xcode’s `Preferences`, navigate to `Components > Toolchains`, and select the installed Swift for TensorFlow toolchain. The name of the toolchain should start with "Swift for TensorFlow".

<p align="center">
  <img src="docs/images/Installation-XcodePreferences.png?raw=true" alt="Select toolchain in Xcode preferences."/>
</p>

On macOS Catalina, `Verify Code Signature` for Swift for TensorFlow toolchains produces a code signature error. This prevents Xcode projects built using Swift for TensorFlow toolchains from running. To work around this issue, go to `Project Target Settings > Signing & Capabilities > + Capability > Hardened Runtime` and check `Disable Library Validation`.

<p align="center">
  <img src="docs/images/Usage-macOSCatalinaHardenedRuntime.png?raw=true" alt="Enable \"Hardened Runtime\" in Xcode preferences."/>
</p>

Swift for TensorFlow does not officially support Xcode Playgrounds, and related bugs are tracked by [TF-500](https://bugs.swift.org/browse/TF-500).

## Visual Studio Code setup for Swift (only tested on Linux)

1. Install the [LLDB extension](https://marketplace.visualstudio.com/items?itemName=vadimcn.vscode-lldb).
2. Install the [Swift extension](https://marketplace.visualstudio.com/items?itemName=vknabel.vscode-swift-development-environment).
3. Build [SourceKit-LSP](https://github.com/apple/sourcekit-lsp#building-on-linux) from sources.
4. Search for swift-lsp-dev from the VS Code extensions view and install it.

Steps 3 and 4 are only required for code outline and navigation, first two steps are sufficient for debugging with LLDB. There are two significant caveats:

* Navigation doesn't work across multiple files. In other words, jumping to a definition in another file than the current one isn't possible.
* Debugging sometimes stops spuriously while stepping through the code. Also, watch doesn't work with expressions.

Debugging and outline workflows match the usual VS Code experience:

<p align="center">
  <img src="docs/images/VSCodeSwiftDebug.png?raw=true" alt="Debugging Swift with VS Code."/>
</p>

<p align="center">
  <img src="docs/images/VSCodeSwiftOutline.png?raw=true" alt="Debugging Swift with VS Code."/>
</p>
