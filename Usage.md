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

### Getting newer Swift builds

The default Swift build running in Colab is typically 2-3 business days behind the head of the [swift/tensorflow branch](https://github.com/apple/swift/tree/tensorflow). To install a newer Swift build (which is typically 2-8 hours behind the head of the swift/tensorflow branch), follow these instructions:

1. Close all Colab tabs in your browser.
2. Open [this Swift installation notebook](https://colab.research.google.com/github/tensorflow/swift/blob/master/notebooks/install_latest_swift.ipynb).
3. In the menu bar, click "Runtime > Reset all runtimes".
4. **Optional**: If you plan to use Swift with a GPU or TPU, use "Runtime > Change runtime type" to set the accelerator on the Swift installation notebook before executing it.
5. Click the play button to the left of the cell and wait until you see `"The newly installed Swift build is:"` in the output area.
6. Now any new Swift notebooks that you open will run against the new Swift build. If you have any Swift notebooks already running, then you must restart their runtime ("Runtime > Restart Runtime") to run them against the new Swift build.


Important note: If you leave your notebook to idle for a while, Colab will garbage collect your runtime. When you start using Colab again, it will re-create a new runtime with the default (older) Swift build. To get the new Swift build back, start over from step 1.

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

```bash
chmod +x inference.swift
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

To use Swift for TensorFlow with Xcode, you must have installed a toolchain from [this page](Installation.md).

1. Open Xcode’s `Preferences`, navigate to `Components > Toolchains`, and select the installed Swift for TensorFlow toolchain. The name of the toolchain should start with "Swift for TensorFlow Development Snapshot".

<p align="center">
  <img src="docs/images/Installation-XcodePreferences.png?raw=true" alt="Select toolchain in Xcode preferences."/>
</p>

2. In the menu bar, select `File > New > Playground...`.

3. Then, select `macOS` and `Blank` and hit `Next`.

4. Choose a location for the Playground file and hit `Create`. Xcode should open your new Playground.

5. In the Playground, let’s try importing TensorFlow! Paste the following code:

```swift
import TensorFlow

let x = Tensor<Float>([[1, 2], [3, 4]])
print(x)
```

6. After a moment, the Playground should finish running and print the result in the display at the bottom.

<p align="center">
  <img src="docs/images/Usage-Playground.png?raw=true" alt="Playground running Swift for TensorFlow."/>
</p>

**Note:** Xcode Playgrounds are a great interactive environment for prototyping code, but they often hang or crash. If that happens, try restarting Xcode. There are some documented bugs regarding Swift for TensorFlow and Playgrounds. If you discover a new bug, please file an issue.

To build an executable with Xcode 10, you must change some project settings from their default values:

 1. In the menu bar, select `File > Project Settings...`.

 2. Then, select `Legacy Build System` for Build Settings and click `Done`.

 3. In your target's Build Settings:
   * Go to `Swift Compiler > Code Generation > Optimization Level` and select `Optimize for Speed [-O]`.
   * Add `libtensorflow.so` and `libtensorflow_framework.so` to `Linked Frameworks and Libraries` and change `Runtime Search Paths`.
     See [this comment](https://github.com/tensorflow/swift/issues/10#issuecomment-385167803) for specific instructions with screenshots.
   * Go to `Linking > Other Linker Flags` and add `-lpython` to the list of flags.
