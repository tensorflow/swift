# Swift for TensorFlow Known Issues

This is a curated list of Swift for TensorFlow known issues and missing
features. With every release, new issues are added and resolved issues are
updated.

Legend:
* Notable issues are marked in **bold**.
* Issues under active development are marked with 🚧.

Please see the [JIRA issue tracker](https://bugs.swift.org/projects/TF/issues)
for a full list of known issues.

## Version 0.4

### Automatic Differentiation
* [ ] Marking stored properties as `@differentiable` may result in a crash.
      ([TF-521])
* [ ] Marking an intializer as `@differentiable` may result in a SIL
      verification error:
      `operand of 'apply' doesn't match function input type`. ([TF-526])
* [ ] Defining custom derivatives for `@_alwaysEmitIntoClient` declarations
      results in a crash. ([TF-545])
* [ ] Differentiating struct initializers may result in a SIL verification
      error: `substituted callee type does not match substitutions`. ([TF-546])

## Version 0.3

### TensorFlow Library

* [ ] `Tensor` advanced indexing and striding are not supported on GPU.

## Version 0.2

### Notebook Environments (Colab and Jupyter)

* [ ] When a runtime error occurs or when you interrupt cell execution,
      resources (e.g. host memory, GPU memory) do not get released. This can
      lead to OOMs. ([TF-338])
  * Workaround: Restart the runtime (`Runtime > Restart Runtime` in the Colab
    menu bar) to release all the resources.
* [ ] If the last statement on a cell evaluates to a struct that was defined in
      the notebook, then you get an error ("use of undeclared type") instead of
      seeing the value of the statement. ([TF-125])
  * Workaround: Wrap the last statement in `print()`.
* [ ] Using extensions to conform a type to a protocol (e.g. `extension MyType:
      MyProtocol { ... }`), often causes duplicate conformance errors.
      ([TF-162])
  * Workaround: Add the conformance in the same cell where the type is defined.
* [ ] If a cell that declares a type executes twice, then it creates two
      different types with the same name. Mixing these types can lead to
      confusing error messages like `cannot convert value of type 'MyType' to
      expected argument type 'MyType'`. ([TF-156])
  * Workaround: Re-run all cells that use the declared type, so that they use the
    new type.
* [ ] The autocomplete UI should show types and documentation. It should
      position your cursor in the first argument when you complete a function
      call.

### Swift Standard Library Enhancements

* [ ] The [`Differentiable`] protocol's `allDifferentiableVariables` requirement
      should not have a setter. Do not use this directly through a generic type
      with a `Differentiable` conformance constraint. ([TF-208])

### TensorFlow Library

* [ ] 🚧 **Model checkpointing and serialization APIs are missing.** ([TF-388])
* [ ] **TensorFlow runtime errors (e.g. shape mismatch errors) do not show useful
      source location information or useful stack traces.** ([TF-458])

### TensorFlow Runtime

* [ ] If you are using a CUDA build and you have an NVIDIA GPU with a compute
      capability other than 3.5 or 7.0, then you will experience a ~10 minute
      delay the first time you execute a TensorFlow operation, while TensorFlow
      compiles kernels for your GPU's compute capability. The program will not
      print anything out and it will appear to be frozen. ([TF-461])
* [ ] There is a long latency when allocating a `Tensor` for the first time on
      GPUs. Subsequent allocations are normal speed. ([TF-460])
* [ ] **TensorFlow runtime errors (e.g. shape mismatch errors) do not show
      useful source location information or useful stack traces.** ([TF-458])

### Swift for TensorFlow Deep Learning Library

* [ ] Many Keras layers remain to be implemented, help wanted! ([swift-apis#54])
* [ ] Parameter sharing APIs (e.g. using the same `Tensor` weights in multiple
      layers) are missing.
* [ ] The [`Parameter`] class does not yet conform to `Differentiable`, and is
      not recommended for general use.
* [ ] The compiler errors displayed when a user-defined layer struct fails to
      fully satisfy the requirements of the `Layer` protocol are unclear.

### Automatic Differentiation

* [ ] 🚧 **Differentiation does not yet support functions with control flow.**
      ([TF-354])
    * Conditionals are supported since 0.4 ([apple/swift#25057]).
* [ ] 🚧 **Higher-order differentiation is not yet supported.**
* [ ] Differentiating functions with respect to an `inout` parameter is not yet
      supported. ([TF-357])
* [ ] The compiler will only synthesize conformance requirements for
      `Differentiable` in `struct` types. ([TF-37])
* [ ] The `@differentiable` attribute incorrectly passes type-checking in some
      cases, when an error should be produced. This leads to compiler crashes.
      ([TF-449])
* [x] ~~The `@differentiating` attribute leads to a compiler crash when the
      derivative function is defined in a generic context that is more
      constrained than the original function's generic context. ([TF-358])~~
  * **Resolved (0.3).** The `@differentiating` attribute can register
    derivatives with a generic context that is more constrained than the
    original function's generic context.
* [ ] Referring to a `@differentiable` function using key paths leads to a
      compiler crash. ([TF-123])

### Python Interoperability

* [ ] Python runtime errors do not show useful source location information.
      The Python call stack should be shown. ([TF-150])
* [ ] When an argument to a Python function cannot be converted to a Python
      object, the compiler wrongly claims that the function is of non-function
      type rather than pointing out that the argument doesn't conform to
      `PythonConvertible`. ([TF-220])
* [ ] Python TensorFlow cannot be imported because of various issues (binary
      incompatibility, symbol conflicts).

[`Differentiable`]: https://www.tensorflow.org/swift/api_docs/Protocols/Differentiable
[`Parameter`]: https://www.tensorflow.org/swift/api_docs/Classes/Parameter

[swift-apis#54]: https://github.com/tensorflow/swift-apis/issues/54
[apple/swift#25057]: https://github.com/apple/swift/pull/25057

[TF-37]: https://bugs.swift.org/browse/TF-37
[TF-123]: https://bugs.swift.org/browse/TF-123
[TF-125]: https://bugs.swift.org/browse/TF-125
[TF-150]: https://bugs.swift.org/browse/TF-150
[TF-156]: https://bugs.swift.org/browse/TF-156
[TF-162]: https://bugs.swift.org/browse/TF-162
[TF-208]: https://bugs.swift.org/browse/TF-208
[TF-220]: https://bugs.swift.org/browse/TF-220
[TF-338]: https://bugs.swift.org/browse/TF-338
[TF-356]: https://bugs.swift.org/browse/TF-356
[TF-357]: https://bugs.swift.org/browse/TF-357
[TF-358]: https://bugs.swift.org/browse/TF-357
[TF-384]: https://bugs.swift.org/browse/TF-384
[TF-388]: https://bugs.swift.org/browse/TF-388
[TF-449]: https://bugs.swift.org/browse/TF-449
[TF-458]: https://bugs.swift.org/browse/TF-458
[TF-459]: https://bugs.swift.org/browse/TF-459
[TF-460]: https://bugs.swift.org/browse/TF-460
[TF-461]: https://bugs.swift.org/browse/TF-461
[TF-521]: https://bugs.swift.org/browse/TF-521
[TF-526]: https://bugs.swift.org/browse/TF-526
[TF-545]: https://bugs.swift.org/browse/TF-545
[TF-546]: https://bugs.swift.org/browse/TF-546
