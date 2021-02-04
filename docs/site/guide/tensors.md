# Tensor overview

The Swift for TensorFlow APIs use the `Tensor` type as the primary means for performing accelerated
computation. A `Tensor` represents a multidimensional array of values, and operations on `Tensor`s
are automatically dispatched to available accelerators using one of two backends.

A `Tensor` is [generic](https://docs.swift.org/swift-book/LanguageGuide/Generics.html) about the 
type of the values it contains. The type of these values must conform to `TensorFlowScalar`, with
common types being `Float`, `Int32`, and `Bool`. For example, to initialize two `Float`-containing
`Tensor`s with some predetermined values, you could do the following:

```swift
let tensor1 = Tensor<Float>([0.0, 1.0, 2.0])
let tensor2 = Tensor<Float>([1.5, 2.5, 3.5])
```

If you had left out the `<Float>` type parameter, Swift would infer a type of `Tensor<Double>`.
`Double` is the default type for floating-point literals in Swift. `Float` values tend to be more
common in machine learning calculations, so we're using that here.

Many common operators work on `Tensor`s. For example, to add two of them and obtain the result, you
can do the following:

```swift
let tensor3 = tensor1 + tensor2
```

The full list of operations you can perform on a `Tensor` is available in 
[the API documentation](https://www.tensorflow.org/swift/api_docs/Structs/Tensor).
