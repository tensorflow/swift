# Hierarchical parameter iteration and optimization

[Richard Wei](https://github.com/rxwei), [Dan Zheng](https://github.com/dan-zheng)

Last updated: March 2019

## Introduction

The concept of parameter optimization is crucial for machine learning algorithms. This document explains the concept of parameters and parameter optimization, shows how TensorFlow (graph mode) and PyTorch handle parameter update, and describes the current design for Swift.

### Parameters and optimization

Machine learning models are conceptually functions with internal state called "parameters". In code, models are often represented as data structures that store parameters as mutable properties and have an "apply" method. Machine learning optimizers "train" models by applying an algorithm (e.g. stochastic gradient descent) to update the parameters of a model.

In Swift, this might look like:

```swift
struct MyMLModel {
    // Parameters.
    var weight1, weight2: Tensor<Float>
    var bias1, bias2: Tensor<Float>

    func applied(to input: Tensor<Float>) {
        let h = relu(input • weight1 + bias1)
        return sigmoid(h • weight2 + bias2)
    }
}

let model = MyMLModel(...)
let input = Tensor<Float>([0.2, 0.4])
print(model.applied(to: input))
```

Here are some additional rules about models and parameters:

1. Not all properties of a model are required to be parameters: a model may have properties which aren't meant to be trainable (e.g. configuration flags or state-caching variables). This requires a clear way to distinguish parameters from other properties.

    ```swift
    struct MyMLModel {
        // These are parameters.
        var weight: Tensor<Float>
        var bias: Tensor<Float>

        // Need to distinguish from non-parameter stored properties.
        let useBias: Bool
        var previousWeight: Tensor<Float>
    }
    ```

2. There must exist some mechanism to update all parameters of a model given their gradients.

    The ability to jointly iterate over parameters and gradients is crucial for writing simple, generic code that works with all models. Without this ability to perform "generic parameter update", users must duplicate code for each parameter, with no potential for generalization:

    ```swift
    // w1, w2, b1, b2: Tensor<Float>
    w1 -= learningRate * dw1
    w2 -= learningRate * dw2
    b1 -= learningRate * db1
    b2 -= learningRate * db2
    ...
    ```

### Existing approaches

Dynamic machine learning frameworks like PyTorch allow ad-hoc model parameter registration and mutation. The base class `Module` defines a custom `__setattr__` function, which internally calls `register_parameter`. `Module` also defines a `parameters()` function which returns all registered parameters.

```python
class Linear(Module):
  def __init__(self, in_features, out_features, bias=True):
    super(Linear, self).__init__()
    self.in_features = in_features
    self.out_features = out_features
    # Following line calls `__setattr__`, which internally calls
    # `register_parameter`.
    self.weight = Parameter(torch.Tensor(out_features, in_features))
    if bias:
      # Following line internally calls `register_parameter`.
      self.bias = Parameter(torch.Tensor(out_features))
    else:
      self.register_parameter('bias', None)
    self.reset_parameters()

# Optimizers are general and work with the parameters of any model.
optimizer = optim.SGD(model.parameters(), lr=0.01)

# The optimizer `step` function loops over parameters/parameter groups.
# Pseudocode:
class SGD(Optimizer):
  def step(self):
    for param in parameters:
      ...
```

However, in Swift, this is difficult. Constructing a collection of parameters is difficult because parameters aren't required to have the same type: for example, a model may have parameters with types `Float`, `Tensor<Float>`, and `Tensor<Double>`. To represent parameters as a collection, advanced type-erasure is needed to generalize all parameter types. It's also not clear how parameter update would work (at compile-time, how is it possible to identify the correct concrete `+` function for a type-erased parameter value?).

Additionally, while we want to enable code that achieves the following:
```swift
for (inout θ, dθ) in zip(parameters, gradients) {
    θ -= learningRate * dθ
}
```

We don't want to actually lower the for-loop or zip operation to TensorFlow (lowering wouldn't be straightforward or and lowered representation wouldn't be efficient). Instead, we want to fully unroll the loop into individual straight-line statements:

```swift
// w1, w2, b1, b2: Tensor<Float>
w1 -= learningRate * dw1
w2 -= learningRate * dw2
b1 -= learningRate * db1
b2 -= learningRate * db2
```

---

TensorFlow (graph mode) handles parameters differently. Let's look at the optimizer example below:

```python
import tensorflow as tf
# Model parameters
W = tf.Variable([0.3], dtype=tf.float32)
b = tf.Variable([-0.2], dtype=tf.float32)

# Training data (inputs/outputs)
x = tf.placeholder(dtype=tf.float32)
y = tf.placeholder(dtype=tf.float32)
x_train = [1, 2, 3, 4]
y_train = [0, 1, 2, 3]

linear_model = W * x + b
squared_deltas = tf.square(linear_model - y_train)
loss = tf.reduce_sum(squared_deltas)

# Optimizer
optimizer = tf.train.GradientDescentOptimizer(learning_rate=0.01)
train = optimizer.minimize(loss=loss)
```

In the last line above: how does the optimizer determine which tensors are parameters to be minimized? This is done implicitly by examining the graph of `loss`: since the only Variables in the graph are `W` and `B`, they are determined to be the parameters and are minimized.

In Swift, TensorFlow graphs are an implementation detail and aren't visible to users: there's no way to inspect whether tensors are placeholders/constants/variables, so the TensorFlow style of implicit parameter analysis is not really suitable. With implicit parameters, it's difficult to work with parameters directly (e.g. to implement a custom optimizer for arbitrary parameters). The authors believe that parameter representation and parameter update are language-design problems and should be explicitly clear in Swift.

## Parameter update in Swift

The current parameter update design in Swift is based on the `KeyPathIterable` protocol.

Machine learning models are data structures with mutable properties called parameters. Optimizers "train" models by applying an algorithm (e.g. stochastic gradient descent) to update the parameters of a model.

The current Swift parameter update design is based on two protocols: `KeyPathIterable` and `Differentiable`.

With this design,
* Users can write machine learning model structs with arbitrary parameters.
* Library authors can write generic algorithms that read and update model parameters, including machine learning optimizers.

Examples:
* [tensorflow/swift-apis][swift-apis]: the Swift for TensorFlow deep learning library. Layers and optimizers are written using `Differentiable` and `KeyPathIterable`.
* [tensorflow/swift-models][swift-models]: Swift for TensorFlow models written using `swift-apis`.

Related discussion:
* [Dynamic property iteration using the `KeyPathIterable` protocol][KeyPathIterable].
* [Differentiable types and the `Differentiable` protocol][Differentiable].

---

### `KeyPathIterable` basics

In Swift, custom property iteration is implemented using key paths and the `KeyPathIterable` protocol. Key paths are a statically-typed mechanism for referring to the properties of a type. The `KeyPathIterable` protocol represents types whose values provide custom key paths to properties or elements. It has two requirements:

```swift
/// A type whose values provides custom key paths to properties or elements.
public protocol KeyPathIterable {
    /// A type that can represent a collection of all key paths of this type.
    associatedtype AllKeyPaths: Collection
        where AllKeyPaths.Element == PartialKeyPath<Self>

   /// A collection of all custom key paths of this value.
    var allKeyPaths: AllKeyPaths { get }
}
```

The compiler can automatically provide an implementation of the `KeyPathIterable` protocol requirements for any struct type, based on its stored properties:

Here’s an example:

```swift
struct DenseLayer: KeyPathIterable {
    var weight: Tensor<Float>
    var bias: Tensor<Float>
    var activation: (Tensor<Float>) -> (Tensor<Float>) = relu

    func applied(to input: Tensor<Float>) -> Tensor<Float> {
        return activation(matmul(input, weight) + bias)
    }
  
    // Note: the code below is compiler synthesized.
    // typealias AllKeyPaths = [PartialKeyPath<DenseLayer>]
    // var allKeyPaths: AllKeyPaths = [\DenseLayer.weight, \DenseLayer.bias, \DenseLayer.activation]
}

var parameters = DenseLayer(weight: [[1, 1], [1, 1]], bias: [1])
for kp in parameters.allKeyPaths {
    print(parameters[keyPath: kp])
}
// Prints:
// [[1.0, 1.0], [1.0, 1.0]]
// 1.0
// (Function)
```

### Mutable key path iteration

`KeyPathIterable` also defines default computed properties and methods for accessing only key paths to a particular type and only writable key paths:

* `func allKeyPaths<T>(to _: T.Type) -> [KeyPath<Self, T>]`
* `func allWritableKeyPaths<T>(to _: T.Type) -> [WritableKeyPath<Self, T>]`

These enable member mutation, which in turn enable basic machine learning optimization:

```swift
var parameters = DenseLayer(weight: [[1, 1], [1, 1]], bias: [1])
let 𝛁parameters = DenseLayer(weight: [[0.5, 0.5], [0.5, 0.5]], bias: Tensor(0.5))
for kp in parameters.allWritableKeyPaths(to: Tensor<Float>.self) {
    parameters[keyPath: kp] -= 0.1 * 𝛁parameters[keyPath: kp]
}
print(parameters)
// DenseLayer(weight: [[0.95, 0.95], [0.95, 0.95]], bias: 0.95)
```

### Nested key path iteration

Machine learning models don’t typically store tensor parameters as top-level stored properties; they usually store layers, which have nested tensor parameters. However, for generality, machine learning optimizers are often defined in terms of operations on tensors. Optimizers must update all nested parameters within models.

```swift
// Example model with nested tensor parameters.
struct Classifier: KeyPathIterable {
    var dense1: DenseLayer
    var dense2: DenseLayer
    var dense3: DenseLayer
}
```

To support this, `KeyPathIterable` defines a `var recursivelyAllKeyPaths: [PartialKeyPath<Self>]` default computed property, which returns an array of all nested key values. There are other default functions for filtering key paths based on type and writability:
* `func recursivelyAllKeyPaths<T>(to _: T.Type) -> [KeyPath<Self, T>]`
* `func recursivelyAllWritableKeyPaths<T>(to _: T.Type) -> [WritableKeyPath<Self, T>]`

Additionally, conformances to `KeyPathIterable` for `Array` and `Dictionary` are provided in the standard library: `Array.allKeyPaths` returns key paths to all elements and `Dictionary.allKeyPaths` returns key paths to all values. This enables `recursivelyAllKeyPaths` to recurse through the elements/values of these collections.

```swift
extension Array: KeyPathIterable {
    public typealias AllKeyPaths = [PartialKeyPath<Array>]
    public var allKeyPaths: [PartialKeyPath<Array>] {
        return indices.map { \Array[$0] }
    }
}

extension Dictionary: KeyPathIterable {
    public typealias AllKeyPaths = [PartialKeyPath<Dictionary>]
    public var allKeyPaths: [PartialKeyPath<Dictionary>] {
        return keys.map { \Dictionary[$0]! }
    }
}
```

Here’s a full example of nested parameter update:

```swift
struct MyMLModel: KeyPathIterable {
    // Parameters.
    var layers: [DenseLayer]
    var finalWeight: Tensor<Float>
    // Non-parameters.
    var isTraining: Bool = true
}

let dense = DenseLayer(weight: [[1, 1], [1, 1]], bias: [1])
var model = MyMLModel(layers: [dense, dense], finalWeight: [[1, 1], [1, 1]])
// Perform update by iterating over recursively all writable key paths to
// the parameter type.
for kp in model.recursivelyAllWritableKeyPaths(to: Tensor<Float>.self) {
    model[keyPath: kp] -= 0.1 * model[keyPath: kp]
}

dump(model)
// ▿ MyMLModel
//   ▿ layers: 2 elements
//     ▿ DenseLayer
//       - weight: [[0.9, 0.9], [0.9, 0.9]]
//       - bias: [0.9]
//       - activation: (Function)
//     ▿ DenseLayer
//       - weight: [[0.9, 0.9], [0.9, 0.9]]
//       - bias: [0.9]
//       - activation: (Function)
//   - finalWeight: [[0.9, 0.9], [0.9, 0.9]]
//   - isTraining: false
```

This concludes the core parameter update design based on `KeyPathIterable`: iterating over recursively all writable key paths to the parameters of a machine learning model enables nested parameter update. 

### Full-fledged optimizer using `Differentiable`

To update a model’s parameters, machine learning optimizers need the gradient with respect to the parameters. In examples from previous sections, we glossed over the type of the gradient. In this section, we'll explain how to write generic algorithms that use a fully-general gradient type.

The `Differentiable` protocol defines a `CotangentVector` associated type that represents gradient values of the conforming type. Thus, the accurate gradient type for a `Model` type conforming to `Differentiable` is `Model.CotangentVector`. Let’s write a core optimizer update function, defined for a generic `Model` type:

```swift
func update<Model: Differentiable & KeyPathIterable>(
    _ model: inout Model,
    with gradient: Model.CotangentVector
) {
    // Perform update by iterating over recursively all writable key paths to
    // the parameter type. Assume a fixed parameter type for now, for simplicity.
    for kp in model.recursivelyAllWritableKeyPaths(to: Tensor<Float>.self) {
        model[keyPath: kp] -= learningRate * gradient[keyPath: kp]
    }
}
```

This update function has a problem: `kp` is a key path with `Model` as the `Root` type, so `gradient[keypath: kp]` doesn't work in general because `gradient` has type `Model.CotangentVector`.

How can we reconcile this type mismatch? The solution lies in the `AllDifferentiableVariables` associated type requirement of the `Differentiable` protocol. In most cases, `Model.AllDifferentiableVariables` is the same type as `Model.CotangentVector`. For example, the following `DenseLayer` has `DenseLayer.AllDifferentiableVariables == DenseLayer.CotangentVector`:

```swift
struct DenseLayer: KeyPathIterable, Differentiable {
    var weight, bias: Tensor<Float>
    @noDerivative var activation: @differentiable (Tensor<Float>) -> Tensor<Float> = relu

    @differentiable
    func applied(to input: Tensor<Float>) -> Tensor<Float> {
        return activation(matmul(input, weight) + bias)
    }
}

var dense = DenseLayer(weight: [[1, 1], [1, 1]], bias: [1])
dump(dense)
// ▿ DenseLayer
//   - weight: [[1.0, 1.0], [1.0, 1.0]]
//   - bias: [1.0]
//   - activation: (Function)

print(dense.allDifferentiableVariables)
// AllDifferentiableVariables(weight: [[1.0, 1.0], [1.0, 1.0]], bias: [1.0])

print(type(of: DenseLayer.CotangentVector.self))
// AllDifferentiableVariables.Type
```

Since `Model.AllDifferentiableVariables` is the same type as `Model.CotangentVector`, we can access them using the same key paths, as in the following full-fledged optimizer:

```swift
// A stochastic gradient descent optimizer.
class SGD<Model, Scalar: TensorFlowFloatingPoint>
    where Model: Differentiable,
          Model.AllDifferentiableVariables: KeyPathIterable,
          Model.AllDifferentiableVariables == Model.CotangentVector
{
    let learningRate: Scalar = 0.01

    func update(_ parameters: inout Model.AllDifferentiableVariables,
                with gradient: Model.CotangentVector) {
        // Iterate over recursively all writable key paths to the parameter type
        // to perform update.
        for kp in parameters.recursivelyAllWritableKeyPaths(to: Tensor<Scalar>.self) {
            parameters[keyPath: kp] -= learningRate * gradient[keyPath: kp]
        }
    }
}

// Example optimizer usage.
var dense = DenseLayer(weight: [[1, 1], [1, 1]], bias: [1, 1])
let input = Tensor<Float>(ones: [2, 2])
let 𝛁dense = dense.gradient { dense in dense.applied(to: input) }

let optimizer = SGD<DenseLayer, Float>()
optimizer.update(&dense.allDifferentiableVariables, with: 𝛁dense)

dump(dense)
// ▿ DenseLayer
//   - weight: [[0.98, 0.98], [0.98, 0.98]]
//   - bias: [0.98, 0.98]
//   - activation: (Function)

print(𝛁dense.weight)
// [[2.0, 2.0], [2.0, 2.0]]
```

This is essentially how optimizers are defined in [tensorflow/swift-apis][swift-apis]. ([tensorflow/swift-apis][swift-apis] uses a [`Layer`][swift-apis-Layer] protocol that conforms to `Differentiable` and `KeyPathIterable` and has more requirements).

### Optimizers with auxiliary variables

Some optimizers have auxiliary variables per parameter: for example, Adam optimizers store the running mean and variance of every parameter and use them in the update calculation.

Such auxiliary variables can be defined as stored properties in the optimizer with type `Model.AllDifferentiableVariables`. The `update` function iterates over these variables jointly, along with parameters and gradients.

```swift
class Adam<Model, Scalar: TensorFlowFloatingPoint>
    where Model: Differentiable,
          Model.AllDifferentiableVariables: KeyPathIterable,
          Model.AllDifferentiableVariables == Model.CotangentVector
{
    public let learningRate: Scalar = 1e-3
    public var beta1: Scalar = 0.9
    public var beta2: Scalar = 0.999
    public let epsilon: Scalar = 1e-8
    public let decay: Scalar = 0

    private var step: Scalar = 0

    // Auxiliary variables: first and second moments.
    private var firstMoments = Model.AllDifferentiableVariables.zero
    private var secondMoments = Model.AllDifferentiableVariables.zero

    public func update(_ model: inout Model.AllDifferentiableVariables,
                       along direction: Model.AllDifferentiableVariables) {
        step += 1
        let learningRate = self.learningRate * 1 / (1 + decay * step)
        let stepSize = learningRate * (sqrt(1 - pow(beta2, step)) / (1 - pow(beta1, step)))
        for kp in model.recursivelyAllWritableKeyPaths(to: Tensor<Scalar>.self) {
            // Access and mutate auxiliary variables using key paths.
            firstMoments[keyPath: kp] =
                firstMoments[keyPath: kp] * beta1 + (1 - beta1) * direction[keyPath: kp]
            secondMoments[keyPath: kp] =
                secondMoments[keyPath: kp] * beta2 + (1 - beta2) *
                     direction[keyPath: kp] * direction[keyPath: kp]
            model[keyPath: kp] -=
                stepSize * firstMoments[keyPath: kp] / (sqrt(secondMoments[keyPath: kp]) + epsilon)
        }
    }
}
```

### Heterogeneous parameter types

Machine learning models may have parameters with different types. To optimize models with heterogeneous parameter types, simply create optimizers for each of the parameter types. Here’s a toy example:

```swift
struct MixedParameters: Differentiable & KeyPathIterable {
    // Two parameters with different types.
    var weight: Tensor<Float>
    var bias: Tensor<Double>
}

// To update parameters, create an optimizer for each parameter type.
var parameters = MixedParameters.AllDifferentiableVariables(weight: [[1, 1], [1, 1]], bias: Tensor(1))
let 𝛁parameters = MixedParameters.AllDifferentiableVariables(weight: [[0.5, 0.5], [0.5, 0.5]], bias: Tensor(0.5))
let floatSGD = SGD<MixedParameters, Float>()
let doubleSGD = SGD<MixedParameters, Double>()
floatSGD.update(&parameters, along: 𝛁parameters)
doubleSGD.update(&parameters, along: 𝛁parameters)

dump(parameters)
// ▿ MixedParameters.AllDifferentiableVariables
//   - weight: [[0.995, 0.995], [0.995, 0.995]]
//   - bias: 0.995
```

In practice, most models are likely to have the same innermost parameter type (e.g. `Tensor<Float>`).

## End-to-end example

Here's an end-to-end example adapted from [tensorflow/swift-apis][swift-apis] demonstrating parameter optimization for a simple XOR classifier.

```swift
public protocol Layer: Differentiable & KeyPathIterable
    where AllDifferentiableVariables: KeyPathIterable {
    ...
}

struct Classifier: Layer {
    var l1, l2: Dense<Float>
    init(hiddenSize: Int) {
        l1 = Dense<Float>(inputSize: 2, outputSize: hiddenSize, activation: relu)
        l2 = Dense<Float>(inputSize: hiddenSize, outputSize: 1, activation: relu)
    }
    @differentiable
    func applied(to input: Tensor<Float>) -> Tensor<Float> {
        let h1 = l1.applied(to: input)
        return l2.applied(to: h1)
    }
}
var classifier = Classifier(hiddenSize: 4)
let optimizer = Adam<Classifier, Float>(learningRate: 0.02)
let x: Tensor<Float> = [[0, 0], [0, 1], [1, 0], [1, 1]]
let y: Tensor<Float> = [[0], [1], [1], [0]]

for _ in 0..<3000 {
    let 𝛁model = classifier.gradient { classifier -> Tensor<Float> in
        let ŷ = classifier.applied(to: x)
        return meanSquaredError(predicted: ŷ, expected: y)
    }
    // Parameter optimization here!
    optimizer.update(&classifier.allDifferentiableVariables, along: 𝛁model)
}

// After training, check prediction vs. expected output.
let ŷ = classifier.inferring(from: x)
print(ŷ)
// [[2.2782544e-05], [0.99999344], [0.99999225], [2.4871624e-06]]
print(y)
// [[0.0], [1.0], [1.0], [0.0]]
```

## Evolution from previous design

The previous design for parameter update in Swift centered around a parameter aggregate representation based on the `ParameterAggregate` protocol, defined below:

```swift
/// A type representing an aggregate of parameters.
public protocol ParameterAggregate {
    /// The parameter type.
    associatedtype Parameter

    /// Update parameters with their gradient values, using an updater function.
    mutating func update(
        withGradients gradients: Self,
        _ updater: (inout Parameter, Parameter) -> Void
    )
}
```

We quickly found that the `ParameterAggregate` is not sufficiently general for defining general optimizers: `ParameterAggregate` is limited to a single parameter type, and the `update` function is limited to updating parameters given one instance of gradients and cannot handle additional auxiliary variables.

By comparison, the new design with `KeyPathIterable` and `Differentiable` is more general. `KeyPathIterable` solves the core problem of parameter update by enabling joint iteration/mutation over all nested parameters of a particular. Compiler synthesis of the `Differentiable.AllDifferentiableVariables` struct enables parameters and their gradients to have the same type and work with the same key paths.

[swift-apis]: https://github.com/tensorflow/swift-apis
[swift-apis-Layer]: https://github.com/tensorflow/swift-apis/blob/master/Sources/DeepLearning/Layer.swift
[swift-models]: https://github.com/tensorflow/swift-models
[KeyPathIterable]: https://github.com/tensorflow/swift/blob/master/docs/DynamicPropertyIteration.md
[Differentiable]: https://github.com/tensorflow/swift/blob/master/docs/DifferentiableTypes.md
