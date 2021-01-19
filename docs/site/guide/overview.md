# Introducing Swift for TensorFlow

> Swift for TensorFlow: No boundaries.

Swift for TensorFlow is a next-generation platform for machine learning,
incorporating the latest research across machine learning, compilers,
differentiable programming, systems design, and beyond. This is an early-stage
project: it is not feature-complete nor production-ready, but it is ready for
_pioneers_ to try in projects, give feedback, and help shape the future!

The Swift for TensorFlow project is currently focusing on 2 kinds of users:

1.  **Advanced ML researchers** who are limited by current ML frameworks. Swift
    for TensorFlow's advantages include seamless integration with a modern
    general-purpose language, allowing for more dynamic and sophisticated
    models. Fast abstractions can be developed in "user-space" (as opposed to in
    C/C++, aka "framework-space"), resulting in modular APIs that can be easily
    customized.

2.  **ML learners** who are just getting started with machine learning. Thanks
    to Swift's support for quality tooling (e.g. context-aware autocompletion),
    Swift for TensorFlow can be one of the most productive ways to start
    learning the fundamentals of machine learning.

## Swift

Swift is an [open source](https://swift.org/) general-purpose programming language, which has a 
large and growing user base.  We chose Swift because it has an
[open language design process](https://github.com/apple/swift-evolution) and for specific technical 
reasons detailed in the 
"[Why *Swift* for TensorFlow](https://github.com/BradLarson/swift/blob/main/docs/WhySwiftForTensorFlow.md)"
document.  We assume that most readers are unfamiliar with it, so we’ll briefly touch on some 
additional important things about it here.

The development of Swift started in 2010, and aimed to bring the best practices in programming 
language design together into one system rather than trying for academic novelty or to religiously 
propagate programming methodologies.  As a result, it supports multi-paradigm development (e.g. 
functional, OOP, generic, procedural, etc) all in one system,  and brings many well-known concepts 
from academic languages (e.g.
[pattern matching](http://alisoftware.github.io/swift/pattern-matching/2016/03/27/pattern-matching-1/), 
[algebraic data types](https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/Enumerations.html),
and type classes) into the forefront.  Instead of strongly encouraging developers to rewrite all 
their code in Swift, it pragmatically focuses on interoperability with other languages, e.g., 
allowing you to directly import C header files and use them without an 
[FFI](https://en.wikipedia.org/wiki/Foreign_function_interface) and (now) the ability to use Python 
APIs without wrappers.

Swift has the audacious goal of spanning all the way from low-level systems programming to 
high-level scripting, with a focus on being
[easy to learn and use](https://www.apple.com/swift/playgrounds/). 
Because Swift needs to be easy to learn and use but also powerful, it relies on the principle of 
[progressive disclosure of complexity](https://www.nngroup.com/articles/progressive-disclosure/), 
which aggressively factors the cost of complexity onto the people who benefit from that complexity. 
The "scripting language feel" combined with high performance is very useful for machine learning.

A final pertinent aspect of the design of Swift is that much of the Swift language is actually 
implemented in its standard library.  "Builtin" types like 
[Int](https://developer.apple.com/documentation/swift/int) and 
[Bool](https://developer.apple.com/documentation/swift/bool) are actually just structs defined in 
the standard library that wrap magic types and operations.  As such, sometimes we joke that Swift 
is just "syntactic sugar for LLVM".

There is a lot more that is cool about Swift and a ton of content available online.  If you are 
interested in learning more about general Swift programming concepts, here are a few links to get 
started:

 - [A Swift Tour](https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/GuidedTour.html) is a skimmable tour of the high level syntax and feel of Swift, and is part of the larger "The Swift Programming Language" book.
 - Value semantics are powerful and play an important role in Swift code, as explained in "[Building Better Apps with Value Types in Swift](https://developer.apple.com/videos/play/wwdc2015/414/)" [[YouTube](https://www.youtube.com/watch?v=av4i3x-aZbM)].
 - Swift supports classic OOP, but has adapted ideas from the Haskell type system.  This is explained in "[Protocol-Oriented Programming in Swift](https://developer.apple.com/videos/play/wwdc2015/408/)" [[YouTube](https://www.youtube.com/watch?v=g2LwFZatfTI)].

One warning: Swift evolved rapidly in its early years, so you should be careful with anything 
before Swift 3 (released in 2016).

## Why Swift for TensorFlow?

Swift for TensorFlow is a new way to develop machine learning models. It
gives you the power of
[TensorFlow](https://www.tensorflow.org) directly integrated into the
[Swift programming language](https://swift.org/about). We believe that
machine learning paradigms are so important that they deserve
**first-class language and compiler support**.

A fundamental primitive in machine learning is gradient-based optimization:
computing function derivatives to optimize parameters. With Swift for
TensorFlow, you can easily differentiate functions using differential
operators like [`gradient(of:)`](https://www.tensorflow.org/swift/api_docs/Functions#/s:10TensorFlow8gradient2of15CotangentVectorQzxcq_xc_tAA14DifferentiableRzSFR_AaFR_AdaFPQy_Rs_r0_lF), or differentiate with respect to an entire
model by calling method [`gradient(in:)`](https://www.tensorflow.org/swift/api_docs/Protocols/Differentiable#/s:10TensorFlow14DifferentiablePAAE8gradient2in15CotangentVectorQzqd__xXE_tSFRd__AaBRd__AfCQyd__Rsd__lF). These differentiation APIs
are not just available for `Tensor`-related concepts—they are
generalized for all types that conform to the [`Differentiable`](https://www.tensorflow.org/swift/api_docs/Protocols/Differentiable)
protocol, including `Float`, `Double`, SIMD vectors, and your own data
structures.

```swift
// Custom differentiable type.
struct Model: Differentiable {
    var w: Float
    var b: Float
    func applied(to input: Float) -> Float {
        return w * input + b
    }
}

// Differentiate using `gradient(at:_:in:)`.
let model = Model(w: 4, b: 3)
let input: Float = 2
let (𝛁model, 𝛁input) = gradient(at: model, input) { model, input in
    model.applied(to: input)
}

print(𝛁model) // Model.TangentVector(w: 2.0, b: 1.0)
print(𝛁input) // 4.0
```

Beyond derivatives, the Swift for TensorFlow project comes with a sophisticated toolchain
to make users more productive. You can run Swift interactively in a Jupyter
notebook, and get helpful autocomplete suggestions to help you explore the
massive API surface of a modern deep learning library. You can [get started
right in your browser in
seconds](https://colab.research.google.com/github/tensorflow/swift/blob/main/docs/site/tutorials/model_training_walkthrough.ipynb)!

Migrating to Swift for TensorFlow is really easy thanks to Swift's powerful
Python integration. You can incrementally migrate your Python code over (or
continue to use your favorite Python libraries), because you can easily call
your favorite Python library with a familiar syntax:

```swift
import TensorFlow
import Python

let np = Python.import("numpy")

let array = np.arange(100).reshape(10, 10)  // Create a 10x10 numpy array.
let tensor = Tensor<Float>(numpy: array)  // Seamless integration!
```
