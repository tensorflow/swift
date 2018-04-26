# Swift for TensorFlow

Welcome to the Swift for TensorFlow development community!

Swift for TensorFlow is the result of first-principles thinking applied to
machine learning frameworks and aims to take TensorFlow usability to new
heights. Swift for TensorFlow is based on the belief that machine learning is
important enough for first-class language and compiler support, and thus works
very differently from normal language bindings.

First-class language and compiler support allow us to innovate in areas that
traditionally were out of bounds for machine learning libraries. Our
programming model combines the performance of TensorFlow graphs with the
flexibility and expressivity of Eager execution, while keeping a strong focus
on improved usability at every level of the stack.

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

Conceptual:

- [Swift for TensorFlow Design Overview](docs/DesignOverview.md)
- [Why *Swift* for TensorFlow?](docs/WhySwiftForTensorFlow.md)

Deeper dives:

- [Graph Program Extraction](docs/GraphProgramExtraction.md)
- [Automatic Differentiation](docs/AutomaticDifferentiation.md)
- [Python Interoperability](docs/PythonInteroperability.md)

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

