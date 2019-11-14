# Swift for TensorFlow Release Notes

## Version 0.3

### Overview

This is the second public release of Swift for TensorFlow, available across
Google Colaboratory, Linux, and macOS. The focus is improving overall stability
and refining APIs.

### Notebook Environments (Colab and Jupyter)

* Install SwiftPM packages using `%install` directives. See [documentation in
  README](https://github.com/google/swift-jupyter#install-directives).
  ([swift-jupyter#45](https://github.com/google/swift-jupyter/pull/45),
  [swift-jupyter#48](https://github.com/google/swift-jupyter/pull/48),
  [swift-jupyter#52](https://github.com/google/swift-jupyter/pull/52))
* `swift-jupyter` can now be installed in a Conda environment. See
  [documentation in
  README](https://github.com/google/swift-jupyter#option-2-using-a-swift-for-tensorflow-toolchain-and-conda).

### Swift Standard Library Enhancements

* `AnyDerivative` has been added, representing a type-erased derivative.
  ([apple/swift#23521](https://github.com/apple/swift/pull/23521))

### TensorFlow Library

* `Tensor` now supports advanced indexing and striding APIs.
  ([apple/swift#24684](https://github.com/apple/swift/pull/23684))
* `Tensor`s are now pretty-printed, based on the format of NumPy.
  ([apple/swift#23837](https://github.com/apple/swift/pull/23837))
* TensorFlow APIs involving shape dimensions, indices, and sizes now use `Int`
  instead of `Int32`.
  ([apple/swift#24012](https://github.com/apple/swift/pull/24012),
  [apple/swift#24110](https://github.com/apple/swift/pull/24110))
* Additional raw TensorFlow operator are now supported.
  ([apple/swift#23777](https://github.com/apple/swift/pull/23777),
  [apple/swift#24096](https://github.com/apple/swift/pull/24096),
  [apple/swift#24120](https://github.com/apple/swift/pull/24120))
  * `SaveV2` (`Raw.saveV2(prefix:tensorNames:shapeAndSlices:tensors:)`)
  * `RestoreV2` (`Raw.restoreV2(prefix:tensorNames:shapeAndSlices:dtypes:)`)
  * `Split` (`Raw.split(splitDim:value:numSplit:)`)
  * `SplitV` (`Raw.splitV(value:sizeSplits:splitDim:numSplit:)`)
* Experimental APIs have been added to group tensor ops into specialized tensor
  functions for further optimization, optionally using XLA compilation.
  ([apple/swift#23868](https://github.com/apple/swift/pull/23868))

### Swift for TensorFlow Deep Learning Library

* The `Layer` protocol's `applied(to:in:)` method has been renamed to `call(_:)`.
  `Layer`s are now "callable" like functions, e.g. `layer(input)`.
  * **Note: this is experimental functionality that is currently [being proposed
    through Swift
    Evolution](https://github.com/apple/swift-evolution/blob/master/proposals/0253-callable.md).**
    Expect potential changes.
* The `context` argument has been removed from `Layer`'s `applied(to:)` method.
  Instead, contexts are now thread-local. ([swift-apis#87](https://github.com/tensorflow/swift-apis/pull/87))
  * Use `Context.local` to access the current thread-local context.
  * Note: layers like `BatchNorm` and `Dropout` check `Context.local` to
    determine whether the current learning phase is training or inference. **Be
    sure to set the context learning phase to `.training` before running a
    training loop.**
  * Use `withContext(_:_:)` and `withLearningPhase(_:_:)` to call a closure
    under a temporary context or learning phase, respectively.
* A `RNNCell` protocol has been added, generalizing simple RNNs, LSTMs, and
  GRUs. ([swift-apis#80](https://github.com/tensorflow/swift-apis/pull/80),
  [swift-apis#86](https://github.com/tensorflow/swift-apis/pull/86))
* New layers have been added.
  * `Conv1D`, `MaxPool1D`, `AvgPool1D`.
    ([swift-apis#57](https://github.com/tensorflow/swift-apis/pull/57))
  * `UpSampling1D`.
    ([swift-apis#61](https://github.com/tensorflow/swift-apis/pull/61))
  * `TransposedConv2D`.
    ([swift-apis#64](https://github.com/tensorflow/swift-apis/pull/64))
  * `GlobalAveragePooling1D`, `GlobalAveragePooling2D`,
    `GlobalAveragePooling3D`.
    ([swift-apis#66](https://github.com/tensorflow/swift-apis/pull/66),
    [swift-apis#65](https://github.com/tensorflow/swift-apis/pull/65),
    [swift-apis#72](https://github.com/tensorflow/swift-apis/pull/72))
* Optimizer stored properties (e.g. `learningRate`) are now mutable.
  ([swift-apis#81](https://github.com/tensorflow/swift-apis/pull/81))

### Automatic Differentiation

* `Array` now conforms to `Differentiable`.
  ([apple/swift#23183](https://github.com/apple/swift/pull/23183))
* The `@differentiating` attribute now works when the derivative function has a
  generic context that is more constrained than the original function's generic
  context. ([apple/swift#23384](https://github.com/apple/swift/pull/23384))
* The `@differentiating` attribute now accepts a `wrt` differentiation parameter
  list, just like the `@differentiable` attribute.
  ([apple/swift#23370](https://github.com/apple/swift/pull/23370))
* The error `function is differentiable only with respect to a smaller subset of
  arguments` is now obsolete.
  ([apple/swift#23887](https://github.com/apple/swift/pull/23887))
* A differentiation-related memory leak has been fixed.
  ([apple/swift#24165](https://github.com/apple/swift/pull/24165))

### Acknowledgements

This release contains contributions from many people at Google, as well as:

Anthony Platanios, Bart Chrzaszcz, Bastian Müller, Brett Koonce, Dante Broggi,
Dave Fernandes, Doug Friedman, Ken Wigginton Jr, Jeremy Howard, John Pope, Leo
Zhao, Nanjiang Jiang, Pawan Sasanka Ammanamanchi, Pedro Cuenca, Pedro José
Pereira Vieito, Sendil Kumar N, Sylvain Gugger, Tanmay Bakshi, Valeriy Van,
Victor Guerra, Volodymyr Pavliukevych, Vova Manannikov, Wayne Nixalo.

## Version 0.2

### Overview

This is the first public release of Swift for TensorFlow, available across
Google Colaboratory, Linux, and macOS. The focus is building the basic technology
platform and fundamental deep learning APIs.

This release includes the core Swift for TensorFlow compiler, the standard
libraries, and the [Swift for TensorFlow Deep Learning
Library](https://github.com/tensorflow/swift-apis). Core functionality includes:
the ability to define, train and evaluate models, a notebook environment, and
natural Python interoperability.

### Notebook Environments (Colab and Jupyter)

* Hit "Tab" to trigger basic semantic autocomplete.
* [Use matplotlib to produce inline
  graphs.](https://github.com/google/swift-jupyter/blob/master/README.md#rich-output)
* Interrupt cell execution by clicking the "stop" button next to the cell.

### Swift Standard Library Enhancements

* Declare a
  [`KeyPathIterable`](https://www.tensorflow.org/swift/api_docs/Protocols/KeyPathIterable)
  protocol conformance to make your custom type provide a collection of key
  paths to stored properties. Read [Dynamic Property Iteration using Key
  Paths](https://github.com/tensorflow/swift/blob/master/docs/DynamicPropertyIteration.md)
  for a deep dive into the design.
* Declare an
  [`AdditiveArithmetic`](https://www.tensorflow.org/swift/api_docs/Protocols/KeyPathIterable)
  protocol conformance to make values of your custom type behave like an
  [additive group](https://en.wikipedia.org/wiki/Additive_group). If the
  declaration is in the same file as the type definition and when all stored
  properties conform to `AdditiveArithmetic`, the compiler will synthesize the
  conformance automatically.
* Declare an
  [`VectorNumeric`](https://www.tensorflow.org/swift/api_docs/Protocols/KeyPathIterable)
  protocol conformance to make values of your custom type behave like a [vector
  space](https://en.wikipedia.org/wiki/Vector_space). If the declaration is in
  the same file as the type definition and when all stored properties conform to
  `VectorNumeric` with the same `Scalar` associated type, the compiler will
  synthesize the conformance automatically.

### Swift for TensorFlow Deep Learning Library

* The [`Layer`](https://www.tensorflow.org/swift/api_docs/Protocols/Layer)
  protocol and [layers](https://www.tensorflow.org/swift/api_docs/Structs/Dense)
  built on top of it.
* The
  [`Optimizer`](https://www.tensorflow.org/swift/api_docs/Protocols/Optimizer)
  protocol and
  [optimizers](https://www.tensorflow.org/swift/api_docs/Classes/SGD) built on
  top of it.
* [Philox](https://www.tensorflow.org/swift/api_docs/Structs/PhiloxRandomNumberGenerator)
  and
  [Threefry](https://www.tensorflow.org/swift/api_docs/Structs/ThreefryRandomNumberGenerator)
  random number generators and [generic random
  distributions](https://www.tensorflow.org/swift/api_docs/Structs/BetaDistribution).
* Sequential layer application utilities:
  [`sequenced(in:through:_:)`](https://www.tensorflow.org/swift/api_docs/Protocols/Differentiable#/s:10TensorFlow14DifferentiablePAAE9sequenced2in7through_6OutputQyd_0_AA7ContextC_qd__qd_0_t5InputQyd__RszAA5LayerRd__AaMRd_0_AKQyd_0_AGRtd__r0_lF)
  and its n-ary overloads.

### Automatic Differentiation

* Declare a conformance to the
  [`Differentiable`](https://www.tensorflow.org/swift/api_docs/Protocols/Differentiable)
  protocol to make a custom type work with automatic differentiation. For a
  technical deep dive, read [Differentiable
  Types](https://github.com/tensorflow/swift/blob/master/docs/DifferentiableTypes.md).
* Use
  [`differentiableFunction(from:)`](https://www.tensorflow.org/swift/api_docs/Functions#/s:10TensorFlow22differentiableFunction4fromq0_x_q_tcq0_5value_15CotangentVectorQz_AEQy_tAEQy0_c8pullbacktx_q_tc_tAA14DifferentiableRzAaJR_AaJR0_r1_lF)
  to form a `@differentiable` function from a custom derivative function.
* Custom differentiation APIs are available in the standard library. Follow the
  [custom differentiation
  tutorial](https://colab.research.google.com/github/tensorflow/swift/blob/master/docs/site/tutorials/custom_differentiation.ipynb)
  to learn how to use them.
  * Gradient checkpointing API:
    [`withRecomputationInPullbacks(_:)`](https://www.tensorflow.org/swift/api_docs/Protocols/Differentiable#/s:10TensorFlow14DifferentiablePAAE28withRecomputationInPullbacksyqd__qd__xcAaBRd__lF).
  * Gradient surgery API:
    [`withGradient(_:)`](https://www.tensorflow.org/swift/api_docs/Protocols/Differentiable#/s:10TensorFlow14DifferentiablePAAE12withGradientyxy15CotangentVectorQzzcF).

### Python Interoperability

* Switch between Python versions using
  [`PythonLibrary.useVersion(_:_:)`](https://www.tensorflow.org/swift/api_docs/Structs/PythonLibrary#/s:10TensorFlow13PythonLibraryV10useVersionyySi_SiSgtFZ).

### Acknowledgements

This release contains contributions from many people at Google, as well as:

Anthony Platanios, Edward Connell, Tanmay Bakshi.
