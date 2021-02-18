# Layers

Just as `Tensor` is our fundamental building block for accelerated parallel computation, most
machine learning models and operations will be expressed in terms of the
[`Layer`](https://github.com/tensorflow/swift-apis/blob/main/Sources/TensorFlow/Layer.swift)
protocol. `Layer` defines an interface for types that take a differentiable input, process it, and
produce a differentiable output. A `Layer` can contain state, such as trainable weights.

`Layer` is a refinement of the `Module` protocol, with `Module` defining the more general case where
the input to the type is not necessarily differentiable. Most components in a model will deal with
differentiable inputs, but there are cases where types may need to conform to `Module` instead.

Models themselves are often defined as `Layer`s, and are regularly composed of other `Layer`s. A 
model or subunit that has been defined as a `Layer` can be treated just like any other `Layer`, 
allowing for the construction of arbitarily complex models from other models or subunits.

To define a custom `Layer` for a model or operation of your own, you generally will follow a
template similar to this:

```swift
public struct MyModel: Layer {
	// Define your layers or other properties here.

	// A custom initializer may be desired to configure the model.
    public init() {}

    @differentiable
    public func callAsFunction(_ input: Tensor<Float>) -> Tensor<Float> {
		// Define the sequence of operations performed on model input to arrive at the output.
		return ...
    }
}
```

The properties of the `Layer` can host trainable components, such as weights and biases, or other
`Layer`s. A custom initializer is a good place to expose customizable parameters for a model, such
as a variable numbers of layers or the output size of a classification model. Finally, the core of
the `Layer` is `callAsFunction()`, where you will define the types for the input and output as well
as the transformation that takes in one and returns the other.

## Built-in layers

Many common machine learning operations have been encapsulated as `Layer`s for you to use when
defining models or subunits. The following is a list of the layers provided by Swift for TensorFlow,
grouped by functional areas:

### Augmentation

- [AlphaDropout](https://www.tensorflow.org/swift/api_docs/Structs/AlphaDropout)
- [Dropout](https://www.tensorflow.org/swift/api_docs/Structs/Dropout)
- [GaussianDropout](https://www.tensorflow.org/swift/api_docs/Structs/GaussianDropout)
- [GaussianNoise](https://www.tensorflow.org/swift/api_docs/Structs/GaussianNoise)

### Convolution

- [Conv1D](https://www.tensorflow.org/swift/api_docs/Structs/Conv1D)
- [Conv2D](https://www.tensorflow.org/swift/api_docs/Structs/Conv2D)
- [Conv3D](https://www.tensorflow.org/swift/api_docs/Structs/Conv3D)
- [Dense](https://www.tensorflow.org/swift/api_docs/Structs/Dense)
- [DepthwiseConv2D](https://www.tensorflow.org/swift/api_docs/Structs/DepthwiseConv2D)
- [SeparableConv1D](https://www.tensorflow.org/swift/api_docs/Structs/SeparableConv1D)
- [SeparableConv2D](https://www.tensorflow.org/swift/api_docs/Structs/SeparableConv2D)
- [TransposedConv1D](https://www.tensorflow.org/swift/api_docs/Structs/TransposedConv1D)
- [TransposedConv2D](https://www.tensorflow.org/swift/api_docs/Structs/TransposedConv2D)
- [TransposedConv3D](https://www.tensorflow.org/swift/api_docs/Structs/TransposedConv3D)
- [ZeroPadding1D](https://www.tensorflow.org/swift/api_docs/Structs/ZeroPadding1D)
- [ZeroPadding2D](https://www.tensorflow.org/swift/api_docs/Structs/ZeroPadding2D)
- [ZeroPadding3D](https://www.tensorflow.org/swift/api_docs/Structs/ZeroPadding3D)

### Embedding

- [Embedding](https://www.tensorflow.org/swift/api_docs/Structs/Embedding)

### Morphological

- [Dilation2D](https://www.tensorflow.org/swift/api_docs/Structs/Dilation2D)
- [Erosion2D](https://www.tensorflow.org/swift/api_docs/Structs/Erosion2D)

### Normalization

- [BatchNorm](https://www.tensorflow.org/swift/api_docs/Structs/BatchNorm)
- [LayerNorm](https://www.tensorflow.org/swift/api_docs/Structs/LayerNorm)
- [GroupNorm](https://www.tensorflow.org/swift/api_docs/Structs/GroupNorm)
- [InstanceNorm](https://www.tensorflow.org/swift/api_docs/Structs/InstanceNorm)

### Pooling

- [AvgPool1D](https://www.tensorflow.org/swift/api_docs/Structs/AvgPool1D)
- [AvgPool2D](https://www.tensorflow.org/swift/api_docs/Structs/AvgPool2D)
- [AvgPool3D](https://www.tensorflow.org/swift/api_docs/Structs/AvgPool3D)
- [MaxPool1D](https://www.tensorflow.org/swift/api_docs/Structs/MaxPool1D)
- [MaxPool2D](https://www.tensorflow.org/swift/api_docs/Structs/MaxPool2D)
- [MaxPool3D](https://www.tensorflow.org/swift/api_docs/Structs/MaxPool3D)
- [FractionalMaxPool2D](https://www.tensorflow.org/swift/api_docs/Structs/FractionalMaxPool2D)
- [GlobalAvgPool1D](https://www.tensorflow.org/swift/api_docs/Structs/GlobalAvgPool1D)
- [GlobalAvgPool2D](https://www.tensorflow.org/swift/api_docs/Structs/GlobalAvgPool2D)
- [GlobalAvgPool3D](https://www.tensorflow.org/swift/api_docs/Structs/GlobalAvgPool3D)
- [GlobalMaxPool1D](https://www.tensorflow.org/swift/api_docs/Structs/GlobalMaxPool1D)
- [GlobalMaxPool2D](https://www.tensorflow.org/swift/api_docs/Structs/GlobalMaxPool2D)
- [GlobalMaxPool3D](https://www.tensorflow.org/swift/api_docs/Structs/GlobalMaxPool3D)

### Recurrent neural networks

- [BasicRNNCell](https://www.tensorflow.org/swift/api_docs/Structs/BasicRNNCell)
- [LSTMCell](https://www.tensorflow.org/swift/api_docs/Structs/LSTMCell)
- [GRUCell](https://www.tensorflow.org/swift/api_docs/Structs/GRUCell)
- [RecurrentLayer](https://www.tensorflow.org/swift/api_docs/Structs/RecurrentLayer)
- [BidirectionalRecurrentLayer](https://www.tensorflow.org/swift/api_docs/Structs/BidirectionalRecurrentLayer)

### Reshaping

- [Flatten](https://www.tensorflow.org/swift/api_docs/Structs/Flatten)
- [Reshape](https://www.tensorflow.org/swift/api_docs/Structs/Reshape)

### Upsampling

- [UpSampling1D](https://www.tensorflow.org/swift/api_docs/Structs/UpSampling1D)
- [UpSampling2D](https://www.tensorflow.org/swift/api_docs/Structs/UpSampling2D)
- [UpSampling3D](https://www.tensorflow.org/swift/api_docs/Structs/UpSampling3D)

# Optimizers

Optimizers are a key component of the training of a machine learning model, updating the model
based on a calculated gradient. These updates ideally will adjust the parameters of a model in such
a way as to train the model.

To use an optimizer, first initialize it for a target model with appropriate training parameters:

```swift
let optimizer = RMSProp(for: model, learningRate: 0.0001, decay: 1e-6)
```

Train a model by obtaining a gradient with respect to input and a loss function, and then update the
model along that gradient using your optimizer:

```swift
optimizer.update(&model, along: gradients)
```

## Built-in optimizers

Several common optimizers are provided by Swift for TensorFlow. These include the following:

- [SGD](https://www.tensorflow.org/swift/api_docs/Classes/SGD)
- [RMSProp](https://www.tensorflow.org/swift/api_docs/Classes/RMSProp)
- [AdaGrad](https://www.tensorflow.org/swift/api_docs/Classes/AdaGrad)
- [AdaDelta](https://www.tensorflow.org/swift/api_docs/Classes/AdaDelta)
- [Adam](https://www.tensorflow.org/swift/api_docs/Classes/Adam)
- [AdaMax](https://www.tensorflow.org/swift/api_docs/Classes/AdaMax)
- [AMSGrad](https://www.tensorflow.org/swift/api_docs/Classes/AMSGrad)
- [RAdam](https://www.tensorflow.org/swift/api_docs/Classes/RAdam)
