# Accelerator backends

It's pretty straightforward to describe a `Tensor` calculation, but when and how that calculation 
is performed will depend on which backend is used for the `Tensor`s and when the results
are needed on the host CPU.

Behind the scenes, operations on `Tensor`s are dispatched to accelerators like GPUs or 
[TPUs](https://cloud.google.com/tpu), or run on the CPU when no accelerator is available. This
happens automatically for you, and makes it easy to perform complex parallel calculations using
a high-level interface. However, it can be useful to understand how this dispatch occurs and be
able to customize it for optimal performance.

Swift for TensorFlow has two backends for performing accelerated computation: TensorFlow eager mode
and X10. The default backend is TensorFlow eager mode, but that can be overridden. An
[interactive tutorial](https://colab.research.google.com/github/tensorflow/swift/blob/main/docs/site/tutorials/introducing_x10.ipynb)
is available that walks you through the use of these different backends.

## TensorFlow eager mode

The TensorFlow eager mode backend leverages
[the TensorFlow C API](https://www.tensorflow.org/install/lang_c) to send each `Tensor` operation
to a GPU or CPU as it is encountered. The result of that operation is then retrieved and passed on
to the next operation.

This operation-by-operation dispatch is straightforward to understand and requires no explicit 
configuration within your code. However, in many cases it does not result in optimal performance 
due to the overhead from sending off many small operations, combined with the lack of operation 
fusion and optimization that can occur when graphs of operations are present. Finally, TensorFlow eager mode is incompatible with TPUs, and can only be used with CPUs and GPUs.

## X10 (XLA-based tracing)

X10 is the name of the Swift for TensorFlow backend that uses lazy tensor tracing and [the XLA
optimizing compiler](https://www.tensorflow.org/xla) to in many cases significantly improve
performance over operation-by-operation dispatch. Additionally, it adds compatibility for
[TPUs](https://cloud.google.com/tpu), accelerators specifically optimized for the kinds of
calculations found within machine learning models.

The use of X10 for `Tensor` calculations is not the default, so you need to opt in to this backend.
That is done by specifying that a `Tensor` is placed on an XLA device:

```swift
let tensor1 = Tensor<Float>([0.0, 1.0, 2.0], on: Device.defaultXLA)
let tensor2 = Tensor<Float>([1.5, 2.5, 3.5], on: Device.defaultXLA)
```

After that point, describing a calculation is exactly the same as for TensorFlow eager mode:

```swift
let tensor3 = tensor1 + tensor2
```

Further detail can be provided when creating a `Tensor`, such as what kind of accelerator to use
and even which one, if several are available. For example, a `Tensor` can be created on the second
TPU device (assuming it is visible to the host the program is running on) using the following:

```swift
let tpuTensor = Tensor<Float>([0.0, 1.0, 2.0], on: Device(kind: .TPU, ordinal: 1, backend: .XLA))
```

No implicit movement of `Tensor`s between devices is performed, so if two `Tensor`s on different
devices are used in an operation together, a runtime error will occur. To manually copy the 
contents of a `Tensor` to a new device, you can use the `Tensor(copying:to:)` initializer. Some 
larger-scale structures that contain `Tensor`s within them, like models and optimizers, have helper
functions for moving all of their interior `Tensor`s to a new device in one step.

Unlike TensorFlow eager mode, operations using the X10 backend are not individually dispatched as
they are encountered. Instead, dispatching to an accelerator is only triggered by either reading
calculated values back to the host or by placing an explicit barrier. The way this works is that
the runtime starts from the value being read to the host (or the last calculation before a manual
barrier) and traces the graph of calculations that result in that value.

This traced graph is then converted to the XLA HLO intermediate representation and passed to the
XLA compiler to be optimized and compiled for execution on the accelerator. From there, the entire
calculation is sent to the accelerator and the end result obtained.

Calculation is a time-consuming process, so X10 is best used with massively parallel calculations
that are expressed via a graph and that are performed many times. Hash values and caching are used so that identical graphs are only compiled once for every unique configuration.

For machine learning models, the training process often involves a loop where the model is
subjected to the same series of calculations over and over. You'll want each of these passes to be
seen as a repetition of the same trace, rather than one long graph with repeated units inside it.
This is enabled by the manual insertion of a call to `LazyTensorBarrier()` function at the 
locations in your code where you wish for a trace to end.

### Mixed-precision support in X10

Training with mixed precision via X10 is supported and both low-level and
high-level API are provided to control it. The
[low-level API](https://github.com/tensorflow/swift-apis/blob/main/Sources/TensorFlow/Core/MixedPrecision.swift)
offers two computed properties: `toReducedPrecision` and `toFullPrecision` which
convert between full and reduced precision, along with `isReducedPrecision`
to query the precision. Besides `Tensor`s, models and optimizers can be converted
between full and reduced precision using this API.

Note that conversion to reduced precision doesn't change the logical type of a
`Tensor`. If `t` is a `Tensor<Float>`, `t.toReducedPrecision` is also a
`Tensor<Float>` with a reduced-precision underlying representation.

As with devices, operations between tensors of different precisions are not
allowed. This avoids silent and unwanted promotion to 32-bit floats, which would be hard
to detect by the user.
