<p align="center">
  <img src="images/logo.png">
</p>

# Swift for TensorFlow

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

## Getting started

### Using Swift for TensorFlow

- **Google Colaboratory**: The fastest way to get started is to try out Swift
   for TensorFlow right in your browser. Just open up [a tutorial](#tutorials-), or start from a [blank
   notebook](https://colab.research.google.com/github/tensorflow/swift/blob/master/notebooks/blank_swift.ipynb)!
   Read more in our [usage guide](Usage.md).

- **Install locally**: you can [download a pre-built Swift for TensorFlow
   package](Installation.md). After installation, you can follow these
   [step-by-step instructions](Usage.md) to build and execute a Swift script on
   your computer.

- **Compile from source**: If you'd like to customize Swift for TensorFlow or
   contribute back, follow our [instructions](https://github.com/apple/swift/tree/tensorflow#building-swift-for-tensorflow)
   on building Swift for TensorFlow from source.

### Tutorials ![](https://www.tensorflow.org/images/colab_logo_32px.png)

Tutorial | Last Updated |
-------- | ------------ |
[A Swift Tour](https://colab.research.google.com/github/tensorflow/swift/blob/master/docs/site/tutorials/a_swift_tour.ipynb) | March 2019
[Protocol-Oriented Programming & Generics](https://colab.research.google.com/github/tensorflow/swift/blob/master/docs/site/tutorials/protocol_oriented_generics.ipynb) | August 2019
[Python Interoperability](https://colab.research.google.com/github/tensorflow/swift/blob/master/docs/site/tutorials/python_interoperability.ipynb) | March 2019
[Custom Differentiation](https://colab.research.google.com/github/tensorflow/swift/blob/master/docs/site/tutorials/custom_differentiation.ipynb) | March 2019
[Model Training Walkthrough](https://colab.research.google.com/github/tensorflow/swift/blob/master/docs/site/tutorials/model_training_walkthrough.ipynb) | March 2019
[Raw TensorFlow Operators](https://colab.research.google.com/github/tensorflow/swift/blob/master/docs/site/tutorials/raw_tensorflow_operators.ipynb) | December 2019

### Resources

- [Models and Examples](https://github.com/tensorflow/swift-models)
- [TensorFlow Swift API Reference](https://www.tensorflow.org/api_docs/swift/Structs/Tensor)
- [Release Notes](RELEASES.md)
- [Known Issues](KNOWN_ISSUES.md)
- [Frequently Asked Questions](FAQ.md)

### Forums

Please join the
[swift@tensorflow.org mailing list](https://groups.google.com/a/tensorflow.org/d/forum/swift)
to hear the latest announcements, get help, and share your thoughts!

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
seconds](https://colab.research.google.com/github/tensorflow/swift/blob/master/docs/site/tutorials/model_training_walkthrough.ipynb)!

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

## Documentation

> Beware: the project is moving very quickly, and thus some of these documents
> are slightly out of date as compared to the current state-of-the-art.

### Overview

Document | Last Updated | Status |
-------- | ------------ | ------ |
[Why *Swift* for TensorFlow?](docs/WhySwiftForTensorFlow.md) | April 2018 | Current
[Swift for TensorFlow Design Overview](docs/DesignOverview.md) | April 2018 | Outdated

### Technology deep dive

The Swift for TensorFlow project builds on top of powerful theoretical
foundations. For insight into some of the underlying technologies, check
out the following documentation.

Document | Last Updated | Status |
-------- | ------------ | ------ |
[Swift Differentiable Programming Manifesto](https://github.com/apple/swift/blob/master/docs/DifferentiableProgramming.md) | January 2020 | Current
[Swift Differentiable Programming Implementation Overview](https://docs.google.com/document/d/1_BirmTqdotglwNTOcYAW-ib6mx_jl-gH9Dbg4WmHZh0) | August 2019 | Current
[Swift Differentiable Programming Design Overview](https://docs.google.com/document/d/1bPepWLfRQa6CtXqKA8CDQ87uZHixNav-TFjLSisuKag/edit?usp=sharing) | June 2019 | Outdated
[Differentiable Types](docs/DifferentiableTypes.md) | March 2019 | Outdated
[Differentiable Functions and Differentiation APIs](docs/DifferentiableFunctions.md) | March 2019 | Outdated
[Dynamic Property Iteration using Key Paths](docs/DynamicPropertyIteration.md) | March 2019 | Current
[Hierarchical Parameter Iteration and Optimization](docs/ParameterOptimization.md) | March 2019 | Current
[First-Class Automatic Differentiation in Swift: A Manifesto](https://gist.github.com/rxwei/30ba75ce092ab3b0dce4bde1fc2c9f1d) | October 2018 | Outdated
[Automatic Differentiation Whitepaper](docs/AutomaticDifferentiation.md) | April 2018 | Outdated
[Python Interoperability](docs/PythonInteroperability.md) | April 2018 | Current
[Graph Program Extraction](docs/GraphProgramExtraction.md) | April 2018 | Outdated

## Source code

Compiler and standard library development happens on the `tensorflow` branch of
the [apple/swift](https://github.com/apple/swift/tree/tensorflow) repository.

Additional code repositories that make up the core of the project include:

 - [Swift fork of LLDB](http://github.com/apple/swift-lldb/tree/tensorflow):
   debugger and REPL support.
 - [Deep learning library](https://github.com/tensorflow/swift-apis): high-level
   API familiar to Keras users.

> Swift for TensorFlow is **not** intended to remain a long-term fork of the official
> Swift language. Language additions are designed to fit with the direction of
> Swift and will go through the [Swift
> Evolution](https://github.com/apple/swift-evolution) process.

### Jupyter Notebook support

[Jupyter Notebook](http://jupyter.org/) support for Swift is under development at
[google/swift-jupyter](https://github.com/google/swift-jupyter).

## Community

Swift for TensorFlow discussions happen on the
[swift@tensorflow.org mailing list](https://groups.google.com/a/tensorflow.org/d/forum/swift).

### Bugs reports and feature requests

Before reporting an issue, please check the [Frequently Asked Questions](FAQ.md)
to see if your question has already been addressed.

For questions about general use or feature requests, please send an email to
the [mailing list](mailto:swift@tensorflow.org) or search for relevant issues
in the [JIRA issue tracker](https://bugs.swift.org/projects/TF/issues/?filter=allopenissues).

For the most part, the core team's development is also tracked in
[JIRA](https://bugs.swift.org/secure/RapidBoard.jspa?rapidView=17&projectKey=TF&view=planning).

### Contributing

We welcome contributions from everyone. Read the [contributing
guide](Contributing.md) for information on how to get started.

### Code of conduct

In the interest of fostering an open and welcoming environment, we as
contributors and maintainers pledge to making participation in our project and
our community a harassment-free experience for everyone, regardless of age, body
size, disability, ethnicity, gender identity and expression, level of
experience, education, socio-economic status, nationality, personal appearance,
race, religion, or sexual identity and orientation.

The Swift for TensorFlow community is guided by our [Code of
Conduct](CODE_OF_CONDUCT.md), which we encourage everybody to read before
participating.
