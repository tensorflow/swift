<p align="center">
  <img src="images/logo.png">
</p>

# Swift for TensorFlow

Welcome to the Swift for TensorFlow development community!

Swift for TensorFlow is a new way to develop machine learning models. It
gives you the full power of
[TensorFlow](https://www.tensorflow.org/programmers_guide/eager) directly 
integrated into the [Swift programming language](https://swift.org).
With Swift, you can write the following imperative code and Swift 
automatically turns it into **a single TensorFlow Graph** and runs it 
with the full performance of TensorFlow sessions.

```swift
import TensorFlow

var x = Tensor([[1, 2, 3]])

for i in 1...100 {
  if x > 50 { break }
  x += tanh(x)
}

print(x)
```

Swift combines the flexibility of 
[Eager execution](https://www.tensorflow.org/programmers_guide/eager) with the 
high performance of [Graphs](https://www.tensorflow.org/programmers_guide/graphs). 
Behind the scenes, Swift analyzes your Tensor code and automatically builds 
graphs for you. Swift also catches type errors and shape error before running your
code. We believe that machine learning tools are so important that they deserve
**a first-class language and a compiler**.

**Note:** Swift for TensorFlow is an early stage research project. It has been
released to enable open source development and is not yet ready for general use
by machine learning developers.

## Installation and Usage

You can download a pre-built package for Swift for TensorFlow
[here](Installation.md). After installing Swift for TensorFlow, you can learn
how to use the project [here](Usage.md).

For instructions on building from source, visit
[google/swift](https://github.com/google/swift/tree/tensorflow).

## Documentation

Below are some documents explaining the Swift for TensorFlow project.

Conceptual overview:

- [Swift for TensorFlow Design Overview](docs/DesignOverview.md)
- [Why *Swift* for TensorFlow?](docs/WhySwiftForTensorFlow.md)

Technical deeper dives:

- [Graph Program Extraction](docs/GraphProgramExtraction.md)
- [Automatic Differentiation](docs/AutomaticDifferentiation.md)
- [Python Interoperability](docs/PythonInteroperability.md)

Swift API reference:

- [TensorFlow](https://www.tensorflow.org/api_docs/swift/Structs/Tensor)

## Source code

Currently, the active development of Swift for TensorFlow will happen under
the "tensorflow" branch of
[google/swift](https://github.com/google/swift/tree/tensorflow).

These projects include:

- The compiler and standard libraries: [google/swift](http://github.com/google/swift/tree/tensorflow)
- Debugger and REPL support: [google/swift-lldb](http://github.com/google/swift-lldb)

As the code matures, we aim to move it upstream to the corresponding
[Swift.org](https://swift.org) repositories.

## Models

You can find example models in
[tensorflow/swift-models](https://github.com/tensorflow/swift-models).

## Community

Discussion about Swift for TensorFlow happens on the
[swift@tensorflow.org](https://groups.google.com/a/tensorflow.org/d/forum/swift)
mailing list.

## Bugs Reports and Feature Requests

Please stay tuned on how to file bugs and feature requests.  For now, please send comments to the mailing list.

## Contributing

We welcome source code contributions: please read the [Contributor
Guide](https://github.com/google/swift/blob/tensorflow/CONTRIBUTING.md) to get
started.  It is always a good idea to discuss your plans on the mailing list
before making any major submissions.

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

