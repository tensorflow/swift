<p align="center">
  <img src="images/logo.png">
</p>

# Swift for TensorFlow

Welcome to the Swift for TensorFlow development community! For discussions, join the [swift@tensorflow.org mailing list](https://groups.google.com/a/tensorflow.org/d/forum/swift).

Swift for TensorFlow is a new way to develop machine learning models. It
gives you the power of
[TensorFlow](https://www.tensorflow.org) directly integrated into the
[Swift programming language](https://swift.org/about).
With Swift, you can write the following imperative code, and Swift 
automatically turns it into **a single TensorFlow Graph** and runs it 
with the full performance of TensorFlow Sessions on CPU, GPU and 
[TPU](https://cloud.google.com/tpu).

```swift
import TensorFlow

var x = Tensor<Float>([[1, 2], [3, 4]])

for i in 1...5 {
    x += x • x
}

print(x)
```

Swift combines the flexibility of 
[Eager Execution](https://www.tensorflow.org/programmers_guide/eager) with the 
high performance of [Graphs and Sessions](https://www.tensorflow.org/programmers_guide/graphs). 
Behind the scenes, Swift analyzes your Tensor code and automatically builds 
graphs for you. Swift also catches type errors and shape mismatches before running 
your code, has the ability to import any Python library, and has
[Automatic Differentiation](https://en.wikipedia.org/wiki/Automatic_differentiation)
built right in. We believe that machine learning tools are so important that they
deserve **a first-class language and a compiler**.

**Note:** Swift for TensorFlow is an early stage project. It has been released
to enable open source development and is not yet ready for general use
by machine learning developers.

## Installation and Usage

You can [download a pre-built package](Installation.md) for Swift for TensorFlow. 
After installation, you can follow these [instructions](Usage.md) to try it out.

For instructions on building from source, visit
[apple/swift](https://github.com/apple/swift/tree/tensorflow).

## Documentation

Below are some documents explaining the Swift for TensorFlow project.

### Conceptual overview

- [Swift for TensorFlow Design Overview](docs/DesignOverview.md)
- [Why *Swift* for TensorFlow?](docs/WhySwiftForTensorFlow.md)
- [Frequently Asked Questions](FAQ.md)

### Technology deep dive

- [Graph Program Extraction](docs/GraphProgramExtraction.md)
- [Automatic Differentiation](docs/AutomaticDifferentiation.md)
- [Python Interoperability](docs/PythonInteroperability.md)

### Swift API reference

- [TensorFlow](https://www.tensorflow.org/api_docs/swift/Structs/Tensor)

### Design proposals

- [One Graph Function per Host Function](https://github.com/tensorflow/swift/blob/master/proposals/OneGraphFunctionPerHostFunction.md)
- [Parameter Update Design](https://github.com/tensorflow/swift/blob/master/proposals/ParameterUpdate.md)

## Source code

The active development of Swift for TensorFlow will happen under the 
"tensorflow" branch of
[apple/swift](https://github.com/apple/swift/tree/tensorflow).

These projects include:

- The compiler and standard libraries: [apple/swift](http://github.com/apple/swift/tree/tensorflow)
- Debugger and REPL support: [apple/swift-lldb](http://github.com/apple/swift-lldb/tree/tensorflow)

Swift for TensorFlow is **not** intended to remain a long-term fork of the official 
Swift language. New language features will eventually go through the Swift evolution process
as part of being considered for being pulled into master.

## Models

You can find example machine learning models at
[tensorflow/swift-models](https://github.com/tensorflow/swift-models).

## Related Projects

### Jupyter Notebook support

[Jupyter Notebook](http://jupyter.org/) support for Swift for TensorFlow is under development at
[google/swift-jupyter](https://github.com/google/swift-jupyter).

## Community

Discussion about Swift for TensorFlow happens on the
[swift@tensorflow.org mailing list](https://groups.google.com/a/tensorflow.org/d/forum/swift).

## Bugs Reports and Feature Requests

Before reporting an issue, please check the [Frequently Asked Questions](FAQ.md) to see if your question has already been addressed.

For questions about general use or feature requests, please report them in this repository or send an email to the [mailing list](mailto:swift@tensorflow.org).

For Swift compiler bugs introduced by Swift for TensorFlow, please file them to [bugs.swift.org](https://bugs.swift.org) within the “Swift for TensorFlow” component.

For bugs in the example models, please report them to [tensorflow/swift-models](https://github.com/tensorflow/swift-models/issues).

## Contributing

We welcome source code contributions: please read 
[Contributing Code](https://swift.org/contributing/#contributing-code).
It is always a good idea to discuss your plans on the mailing list
before making any major submissions.

The compiler and the standard library have the most [open issues](https://github.com/google/swift/issues).
To get started, you can try to tackle issues labeled "good first issue".

## Code of Conduct

In the interest of fostering an open and welcoming environment, we as
contributors and maintainers pledge to making participation in our project and
our community a harassment-free experience for everyone, regardless of age, body
size, disability, ethnicity, gender identity and expression, level of
experience, education, socio-economic status, nationality, personal appearance,
race, religion, or sexual identity and orientation.

The Swift for TensorFlow community is guided by our [Code of
Conduct](CODE_OF_CONDUCT.md), which we encourage everybody to read before
participating.

