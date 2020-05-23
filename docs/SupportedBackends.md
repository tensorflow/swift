# Swift For Tensorflow Backends

Accelerated calculations in Swift for TensorFlow are performed through the Tensor type. Currently, there are two options for how that acceleration is performed: eager mode or XLA compiler backed lazy tensor mode (X10). 

## Eager Backend

This is the default mode. Execution is eagerly performed an operation-by-operation basis using the [TensorFlow's 2.x eager execution](https://www.tensorflow.org/guide/eager) without creating graphs. 

The [eager backend](https://github.com/tensorflow/swift-apis/blob/master/Sources/TensorFlow/Bindings/EagerExecution.swift) supports CPUs and GPUs.  It does *not* support TPUs.



## X10 (XLA Compiler Based)

The [X10 backend](https://github.com/tensorflow/swift-apis/blob/master/Sources/x10/swift_bindings/doc/API_GUIDE.md) is backed by [XLA](https://www.tensorflow.org/xla) and tensor operations are lazily evaluated. Operations are recorded in a graph until the results are needed. This allows for optimizations such as fusion into one graph.  

This backend provides improved performance over the eager backend in many cases. However, if the model changes shapes at each step, recompilation costs might outweigh the benefits.  See the [X10 Troubleshooting Guide](https://github.com/tensorflow/swift-apis/blob/master/Sources/x10/swift_bindings/doc/TROUBLESHOOTING.md) for more details.

X10 supports CPUs, GPUs, and TPUs.

## Usage

Check out this [Colab notebook](https://github.com/tensorflow/swift/blob/master/docs/site/tutorials/introducing_x10.ipynb) to learn how to switch between the eager and X10 backends.

