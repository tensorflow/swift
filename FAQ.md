# Frequently Asked Questions

This is a list of questions we frequently get and problems that are often encountered. 
Because this project is still in development, we have missing pieces that are commonly
encountered and prefer not to get new issues filed in our bug tracker.

* [Why Swift?](#why-swift)
* [Why do I get "error: array input is not a constant array of tensors"?](#why-do-i-get-error-array-input-is-not-a-constant-array-of-tensors)
* [How can I use Python 3 with the Python module?](#how-can-i-use-python-3-with-the-python-module)
* [\[Mac\] I wrote some code in an Xcode Playground. Why is it frozen/hanging?](https://github.com/tensorflow/swift/blob/master/FAQ.md#mac-i-wrote-some-code-in-a-xcode-playground-why-is-it-frozenhanging)

## Why Swift?

The short answer is that our decision was driven by the needs of the core [Graph Program
Extraction](docs/GraphProgramExtraction.md) compiler transformation that started the whole
project.  We have a long document that explains all of this rationale in depth named "[Why 
*Swift* for TensorFlow?](docs/WhySwiftForTensorFlow.md)".

Separate from that, Swift really is a great fit for our purposes, and a very nice language.

## Why do I get ["error: array input is not a constant array of tensors"](https://github.com/tensorflow/swift/issues/10)?

If you ran into this error, you likely wrote some code using `Tensor` without running Swift with optimizations (`-O`). 

The `-O` flag enables optimizations and is currently required for the [graph program extraction
algorithm](https://github.com/tensorflow/swift/blob/master/docs/GraphProgramExtraction.md) to work correctly.
We're working on making `-O` not required, but in the meantime you need to specify it.

Here's how to enable optimizations in different environments:

* REPL: No need to add extra flags. Optimizations are on by default. 
* Interpreter: `swift -O main.swift`
* Compiler: `swiftc -O main.swift`
* `swift build`: `swift build -Xswiftc -O`
* Xcode: Go to `Build Settings > Swift Compiler > Code Generation > Optimization Level` and select `Optimize for Speed [-O]`.
  * You may also need to add `libtensorflow.so` and `libtensorflow_framework.so` to `Linked Frameworks and Libraries` and change `Runtime Search Paths`.
    See [this comment](https://github.com/tensorflow/swift/issues/10#issuecomment-385167803) for specific instructions with screenshots.

## How can I use Python 3 with the `Python` module?

Currently, Swift is hard-coded to use Python 2.7.
Adding proper Python 3 support is non-trivial but in discussion.
See [this issue](https://github.com/tensorflow/swift/issues/13) for more information.

## [Mac] I wrote some code in an Xcode Playground. Why is it frozen/hanging?

Xcode Playgrounds are known to be somewhat unstable, unfortunately.
If your Playground appears to hang, please try restarting Xcode or creating a new Playground.
