# Parameter Update Design

* Authors: [Dan Zheng](https://github.com/dan-zheng), [Richard Wei](https://github.com/rxwei)

## Introduction

The concept of parameter update is crucial for implementing general machine learning optimization algorithms. This document explains the concept of parameters and parameter update, shows how TensorFlow (graph mode) and PyTorch handle parameter update, and describes the current design for Swift.

### Parameters and parameter aggregates

Machine learning models are data structures with mutable properties called parameters. Machine learning optimizers "train" models by applying an algorithm (e.g. stochastic gradient descent) to update the parameters of a model.

In Swift, this might look like:

```swift
struct MyMLModel {
  // Parameters.
  var weight1, weight2: Tensor<Float>
  var bias1, bias2: Float

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
  var bias: Float

  // Need to distinguish from non-parameter stored properties.
  let useBias: Bool
  var previousWeight: Tensor<Float>
}
```

2. There must exist some mechanism to update all parameters of a model given their gradients.

Let "parameter aggregate" refer to some representation of all of the parameters of a model (e.g. `model.parameters()` in PyTorch). A parameter aggregate representation is important because it enables writing general optimizers that can be used with any model. A basic optimizer parameter update function looks like:

```swift
// Pseudocode: `Parameters` is some data structure representing a model's 
// parameters.
func optimize(parameters: inout Parameters, gradients: Parameters) {
  for (inout θ, dθ) in zip(parameters, gradients) {
    // Different values of θ may have different types. It should be 
    // possible to perform any operation on θ and dθ that they support.
    θ -= learningRate * dθ
  }
}
```

The ability to jointly iterate over parameters and gradients is crucial for writing simple, generic code that works with all models. Without this ability to perform "aggregate parameter update", users must duplicate code for each parameter, with no potential for generalization:

```swift
// w1, w2: Tensor<Float>
// b1, b2: Float
w1 -= learningRate * dw1
w2 -= learningRate * dw2
b1 -= learningRate * db1
b2 -= learningRate * db2
...
```

### Challenges and existing approaches

The "aggregate parameter update" problem can be split into two subproblems:
* How can we represent an aggregate of parameters with different types?
  * This must be done in a way that's compatible with automatic differentiation, e.g. differentiation with respect to "all parameters" must be possible.
* How can we update parameter aggregates with their gradients?

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

However, in Swift, this is difficult. Constructing a collection of parameters is difficult because parameters aren't required to have the same type: for example, a model may have parameters with types `Float`, `Tensor<Float>`, and `Tensor<Double>`. To represent parameters as a collection, advanced type-erasure is needed to generalize all parameter types. It's also not clear how parameter updates would work (at compile-time, how is it possible to identify the correct concrete `+` function for a type-erased parameter value?).

Additionally, while we want to enable code that achieves the following:
```swift
for (inout θ, dθ) in zip(parameters, gradients) {
  θ -= learningRate * dθ
}
```

We don't want to actually lower the for-loop or zip operation to TensorFlow (lowering wouldn't be straightforward or and lowered representation wouldn't be efficient). Instead, we want to fully unroll the loop into individual straight-line statements:

```swift
// w1, w2: Tensor<Float>
w1 -= learningRate * dw1
w2 -= learningRate * dw2
// b1, b2: Float
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

In Swift, TensorFlow graphs are an implementation detail and aren't visible to users: there's no way to inspect whether tensors are placeholders/constants/variables, so the TensorFlow style of implicit parameter analysis is not really suitable. With implicit parameters, it's difficult to work with parameters directly (e.g. to implement a custom optimizer for arbitrary parameters). The authors believe that parameter representation and aggregate parameter update are language-design problems and should be explicitly clear in Swift.

## Parameter update in Swift

The current Swift parameter update design is based on two protocols: `ParameterAggregate` and `Parameterized`.

They enable:
* Parameter update for parameter aggregates and parameterized models, where all parameters have the same type.
* Nested parameter aggregates and parameterized models as parameters, which is important for layer-based high level APIs.
* General optimizers that work with any floating-point parameter aggregate type.

Examples:
* [MNIST](https://github.com/tensorflow/swift-models/blob/master/MNIST/MNIST.swift): demonstrates `ParameterAggregate`.
* [Autoencoder](https://github.com/tensorflow/swift-models/blob/master/Autoencoder/Autoencoder.swift): demonstrates `Parameterized`.
* Optimizers are a work-in-progress, see a sample sketch in this [PR description](https://github.com/apple/swift/pull/18171#issue-203387822).

Implementation:
* [Part 1: ParameterAggregate protocol and synthesis](https://github.com/apple/swift/pull/18140)
* [Part 2: Parameterized protocol and synthesis](https://github.com/apple/swift/pull/18171)

---

Two protocols have been added to the TensorFlow module: `ParameterAggregate` and `Parameterized`.

The `ParameterAggregate` protocol represents an aggregate of parameters. Types that conform to `ParameterAggregate` must specify a `Parameter` associated type and an update method.

```swift
/// A type representing an aggregate of parameters.
public protocol ParameterAggregate {
  /// The parameter type.
  associatedtype Parameter

  /// Update parameters with their gradient values, using an update function.
  mutating func update(
    withGradients gradients: Self,
    _ updateParameter: (inout Parameter, Parameter) -> Void
  )
}
```

For structs whose stored properties all have the same type, the compiler can synthesize the `ParameterAggregate` protocol requirements.

Here's an example:

```swift
struct Parameters : ParameterAggregate {
  // Note: all stored properties have the same type.
  var w: Tensor<Float>
  var b: Tensor<Float>

  // Note: all code below is compiler synthesized.

  // The `Parameter` associated type is synthesized to be the common stored
  // property type.
  // typealias Parameter = Tensor<Float>

  // The synthesized `update` method applies the `update` argument to each
  // parameter-gradient pair.
  // mutating func update(
  //   withGradients gradients: Parameters,
  //   _ updateParameter: (inout Parameter, Parameter) -> Void
  // ) {
  //   updateParameter(&w, gradients.w)
  //   updateParameter(&b, gradients.b)
  // }
}

// Contrived parameter update example.
var parameters = Parameters(w: [[1, 1], [1, 1]]), b: Tensor(1))
let gradients = Parameters(w: [[0.5, 0.5], [0.5, 0.5]], b: Tensor(0.5))
parameters.update(withGradients: gradients) { p, g in
  p -= 0.1 * g
}
print(parameters)
// Parameters(w: [[0.95, 0.95], [0.95, 0.95]], b: 0.95)
```

Model creators can define custom structs that conforms to `ParameterAggregate`, and use them in functions:

```swift
/// Parameters of an MNIST classifier.
struct MNISTParameters : ParameterAggregate {
  var w1 = Tensor<Float>(randomUniform: [784, 30])
  var w2 = Tensor<Float>(randomUniform: [30, 10])
  var b1 = Tensor<Float>(zeros: [1, 30])
  var b2 = Tensor<Float>(zeros: [1, 10])
}

func inference(input: Tensor<Float>, parameters: MNISTParameters) {
  // Forward pass.
  let z1 = images • parameters.w1 + parameters.b1
  let h1 = sigmoid(z1)
  let z2 = h1 • parameters.w2 + parameters.b2
  return sigmoid(z2)
}
```

Automatic differentiation in Swift will support differentiating with respect to structs like `MNISTParameters`:

```swift
func inference(input: Tensor<Float>, parameters: MNISTParameters) { ... }

let dInference = #gradient(inference)
...
```

---

`ParameterAggregate` is useful for representing structs that are "bundles of parameters", where all stored properties are parameters. However, model structs may have stored properties which are not parameters (e.g. configuration flags or state-caching variables), and thus they cannot conform to `ParameterAggregate`.

The `Parameterized` protocol solves this problem. `Parameterized` represents a type whose values have parameters, and where not all stored properties are necessarily parameters.

```swift
public protocol Parameterized {
  /// The type representing all parameters, synthesized from stored properties
  /// marked with `@TFParameter`.
  associatedtype Parameters

  /// A synthesized instance of `Parameters`.
  var allParameters: Parameters { get set }
}
```

Instances of `Parameterized` types have parameters, represented as stored properties marked with the `@TFParameter` attribute.

```swift
struct Model : Parameterized {
  @TFParameter var w: Tensor<Float>
  @TFParameter var b: Tensor<Float>
}
```

For types that conform to `Parameterized`, the compiler can synthesize a member struct type `Parameters` (which includes all of the marked properties) and a computed instance `allParameters`.

If all parameters have the same type, the compiler also synthesizes a conformance of `Parameters` to `ParameterAggregate`.

```swift
struct Model : Parameterized {
  @TFParameter var w: Tensor<Float>
  @TFParameter var b: Tensor<Float>

  // Compiler-synthesized:
  //
  // struct Parameters : ParameterAggregate {
  //   var w: Tensor<Float>
  //   var b: Tensor<Float>
  //
  //   typealias Parameter = Tensor<Float>
  //
  //   mutating func update(
  //     withGradients gradients: Parameters,
  //     _ updateParameter: (inout Parameter, Parameter) -> Void
  //   ) {
  //     updateParameter(&w, gradients.w)
  //     updateParameter(&b, gradients.b)
  //   }
  //
  // var allParameters: Parameters {
  //   get { return Parameters(w: w, b: b)
  //   set { w = newValue.w; b = newValue.b }
  // }
}
```

The `Parameterized` protocol also conditionally defines an `updateParameters` function, when `Parameters` conforms to `ParameterAggregate`:

```swift
public extension Parameterized where Parameters : ParameterAggregate {
  /// Update parameters with their gradient values, using an update function.
  @inlinable
  mutating func updateParameters(
    withGradients gradients: Parameters,
    _ updateParameter: (inout Parameters.Parameter, Parameters.Parameter) -> Void) {
    allParameters.update(withGradients: gradients, updateParameter)
  }
}
```

### Nested parameters

In layer-based high level APIs, layers may have parameters which are themselves layers.

The current parameter design supports this:
* `ParameterAggregate` has special behavior for stored properties that conform to `ParameterAggregate`.
* `Parameterized` has special behavior for parameters that conform to `Parameterized`.

The behavior is perhaps most easily explained via an example:

```swift
struct DenseLayer : Parameterized {
  @TFParameter var w: Tensor<Float>
  @TFParameter var b: Tensor<Float>
  // Synthesized code omitted for brevity, see `struct Model `above for reference.
}

struct Model : Parameterized {
  // Since `DenseLayer` conforms to `Parameterized`, the corresponding `layer`
  // stored property in the `Parameters` struct has type `DenseLayer.Parameters`.
  @TFParameter var layer: DenseLayer
  @TFParameter var tensor: Tensor<Float>

  // Synthesized:
  // struct Parameters : ParameterAggregate {
  //   // Since `DenseLayer.Parameters` conforms to `ParameterAggregate`, its
  //   // "effective parameter type" is considered to be 
  //   // `DenseLayer.Parameters.Parameter`. This ultimately enables nested
  //   // parameters.
  //
  //   var layer: DenseLayer.Parameters
  //   var tensor: Tensor<Float>
  //
  //   // The `DenseLayer.Parameters.Parameter` is `Tensor<Float>`.
  //   // Since all stored properties have the same "effective parameter type",
  //   // `ParameterAggregate` synthesis is possible.
  //   typealias Parameter = Tensor<Float>
  //
  //   mutating func update(
  //     withGradients gradients: Parameters,
  //     _ updateParameter: (inout Parameter, Parameter) -> Void
  //   ) {
  //     layer.update(withGradients: gradients.layer1, updateParameter)
  //     updateParameter(&tensor, gradients.tensor)
  //   }
  //   var allParameters: Parameters {
  //     get { return Parameters(layer: layer.parameters, tensor: tensor)
  //     set { layer.allParameters = newValue.layer; tensor = newValue.tensor }
  //   }
  // }
}
```

## Future directions

### Heterogenous parameter types

The current parameter update design only supports parameters with the same type.
For example, synthesis below doesn't work:

```swift
// The compiler cannot synthesize `ParameterAggregate` requirements because 
// there is no unified parameter type.
struct HeterogeneousParameters : ParameterAggregate {
  var w: Tensor<Double>
  var b: Tensor<Float>
}

// `Parameters` and `allParameters` are synthesized, but the `Parameters` 
// struct does not conform to `ParameterAggregate` because there is no 
// unified parameter type.
struct ModelWithHeterogeneousParameters : Parameterized {
  @TFParameter var w: Tensor<Double>
  @TFParameter var b: Tensor<Float>
}
```

It's technically possible to manually conform `HeterogeneousParameters` to `ParameterAggregate`, but it requires casting and is very inefficient.

One way to enable heterogeneous floating-point tensor parameters is adding support for generic closures in Swift (a subset of rank-2 polymorphism). Generic closures would enable the following:

```swift
struct Parameters : ParameterAggregate {
  var w: Tensor<Double>
  var b: Tensor<Float>

  func update(
    withGradients gradients: Parameters,
    _ updateParameter: <Scalar : BinaryFloatingPoint>(inout Tensor<Scalar>, Tensor<Scalar>) -> Void
  ) {
    updateParameter(&w, gradients.w)
    updateParameter(&b, gradients.b)
  }
}
```

### Parameter groups

Oftentimes, it is useful to categorize parameters into groups in order to perform different computation.

For example, PyTorch has the notion of [parameter groups](https://pytorch.org/docs/stable/optim.html#per-parameter-options):

> Optimizers also support specifying per-parameter options. To do this, instead of passing an iterable of Variables, pass in an iterable of dicts. Each of them will define a separate parameter group, and should contain a params key, containing a list of parameters belonging to it. 
> 
> ```python
> optim.SGD([
>   {'params': model.base.parameters()},
>   {'params': model.classifier.parameters(), 'lr': 1e-3}
> ], lr=1e-2, momentum=0.9)
> ```
> 
> This means that `model.base`‘s parameters will use the default learning rate of 1e-2, `model.classifier`‘s parameters will use a learning rate of 1e-3, and a momentum of 0.9 will be used for all parameters.

The current parameter update design does not yet support parameter groups.

The authors agree that parameter groups are best modeled using a separate "GroupParameterized" protocol, rather than squeezing the functionality into `Parameterized`.

Semantically, "GroupParameterized" and `Parameterized` are quite different. For example, it may not make sense to synthesize an `allParameters` computed property for group-parameterized types (since `allParameters` is an implicit group of "all parameters", which might not make sense for a type that has explicit parameter grouping). Building upon that logic, for a group-parameterized type, it makes sense to update each parameter group individually, rather than all parameters at once.

### Complex iteration and mutation of parameters (implementation in progress)

Currently, `ParameterAggregate` only defines one function: `update(withGradients:_:)`.

This functionality is limited and insufficient for implementing complex optimizers.
For example, an Adam optimizer implementation requires creating auxiliary variables (moving averages) per parameter, and iterating over them jointly with parameters and their gradients:

```swift
// Pseudocode.
struct AdamOptimizer<P : ParameterAggregate> where ... {
  // There is one moving average per parameter.
  // Thus, the moving averages can be represented as an instance of `P`.
  // Note: `P(0)` is pseudocode that initializes all members of `P` to 0. This
  // kind of direct zero initialization isn't possible, but is used here to
  // keep the example code simple.
  var movingAverages = P(0)

  mutating func fitParameters(
    parameters: inout P, withGradients gradients: P
  ) {
    // There needs to be some way to jointly iterate over `parameters`,
    // `gradients`, and `movingAverages`.
    // `parameters.update(withGradients:_:)` is insufficient because it
    // enables iteration over only parameters and gradients simultaneously.
  }
}
```

#### Proposed solution

We can access members of a `ParameterAggregate`-conforming type using key paths.

By synthesizing an `allKeyPaths` static property for types conforming to `ParameterAggregate`, we can jointly iterate over the members of instances of a `ParameterAggregate`-conforming type and access/mutate them arbitrarily.

Implementing the Adam optimizer becomes possible:

```swift
struct AdamOptimizer<P : ParameterAggregate> where ... {
  var movingAverages = P(0)
  mutating func fitParameters(
    parameters: inout P, withGradients gradients: P
  ) {
    for kp in P.allKeyPaths {
      // It's possible to access/mutate members of instances of `P` freely.
      movingAverages[keyPath: kp] = ...
      parameters[keyPath: kp] = gradients[keyPath: kp] ...
    }
  }
}
```

Without additional compiler support, code using such key paths should work via sends/receives.
Eventually, support may be added to evaluate such key path initialization/application at compile-time, and to fully unroll loops iterating over arrays of such key paths.

#### Implementation steps

1. Synthesize `allKeyPaths` static property for types that conform to `ParameterAggregate`. This should enable the implementation of optimizers like Adam. ([SR-8457](https://bugs.swift.org/browse/SR-8457))
2. Investigate compile-time evaluation of key path initialization/arrays. That `KeyPath`s are classes may complicate things.
3. Investigate full unrolling of loops over `allKeyPaths` at compile-time.

Perhaps a TensorFlow-specific attribute (e.g. `@TensorFlowUnroll`) may be added:
```swift
struct P : ParameterAggregate {
  var x1, x2, ...
}
var parameters: P = ...

@TensorFlowUnroll
for kp in P.allKeyPaths {
  parameters[keyPath: kp] = ...
}

// The for-loop becomes keypath-free straight line code:
// parameters.x1 = ...
// parameters.x2 = ...
// ...
```

4. Remove `update(withGradients:_:)` as a protocol requirement and reimplement it as an extension method on `ParameterAggregate`.

Sample implementation:
```swift
public extension ParameterAggregate {
  mutating func update(
    withGradients gradients: Self,
    _ updateParameter: (inout Parameter, Parameter) -> Void
  ) {
    for kp in Self.allKeyPaths {
      updateParameter(&self[keyPath: kp], gradients[keyPath: kp])
    }
  }
}
```

This should be done when a keypath-based implementation of `update(withGradients:_:)` is equally efficient as the current synthesized implementations.

## Alternatives and rationale

Alternative designs are documented in this section.

### `Array` representation of parameters

An alternative to representing parameters as a struct is to represent parameters as some sort of collection, like an `Array`:

```swift
struct MyModel {
  @TFParameter var weight: Tensor<Float>
  @TFParameter var bias: Tensor<Float>

  // Compiler-synthesized `allParameters` computed property.
  var allParameters: [Tensor<Float>] {
    get { return [weight, bias] }
    set { weight = newValue[0]; bias = newValue[1] }
  }
}
```

However, this idea falls apart for parameters with heterogeneous types.

This approach requires using some kind of type-erased collection to store parameters. However, Swift currently doesn't support storing values whose type contains some protocol type (e.g. `var parameters: [FloatingPoint]` is invalid because `FloatingPoint` is a protocol). This is a feature called generalized existentials, which is on the roadmap for Swift generics but is unlikely to be implemented within the next 1-2 years.

To work around the lack of generalized existentials, an advanced type erasure system would be necessary: `var allParameters: [AnyFloatingPointScalarOrVectorNumeric]`, where `AnyFloatingPointScalarOrVectorNumeric` is a type-erased struct type.

Even with such a type-erased data structure, it's not clear how parameter update would work.
If `θ` has type `AnyFloatingPointScalarOrVectorNumeric`, how is it possible to determine the correct `-=` and `*` operators to call in `θ -= learningRate * dθ` at compile time, since the concrete type of `θ` has been erased? 

Additionally, type-erasure may limit the kind of operators that may be applied to parameters. It doesn't make sense for `AnyFloatingPointScalarOrVectorNumeric` to define a `matmul` function because `matmul` is not defined for scalars. However, if a model's parameters all have type `Tensor<Float>`, then it should be possible to call `matmul`. Solving this may require a complex type-erasure hierarchy (adding types like `AnyFloatingPointVectorNumeric`).

### Dynamic parameter registration (using a `registerParameter` function)

An alternative to registering parameters with the `@TFParameter` attribute is to use a special "register parameter" function to indicate parameters, a la PyTorch:

```swift
struct MyModel {
  var weight: Tensor<Float>
  var bias: Float

  init(weight: Tensor<Float>, bias: Float) {
    self.weight = weight
    self.bias = bias
    // Magic function for registering parameters.
    registerParameter(self.weight)
    registerParameter(self.bias)
  }
}
```

An explicit "register parameter" function is more flexible. Here's a toy example: a struct may contain two different models (e.g. a ResNet and RNN model) but use only one of them based on an initialization flag.

```swift
struct ToyModel {
  // Both `ResNetModel` and `RNNModel` are structs with their own
  // parameters.
  var resnet: ResNetModel
  var rnn: RNNModel

  init(resnet: ResNetModel, rnn: RNNModel, useResNet: Bool) { ... }
}
```

With the `@TFParameter` approach, both the `resnet` and `rnn` stored properties must be marked with `@TFParameter`, causing `ToyModel.Parameters` to contain the parameters of both of the two. With a "register parameter" function, it's possible to register only the parameters of `resnet` or `rnn` conditionally, resulting in less redundant computation and a smaller graph size when performing parameter update.

```swift
if useResNet {
  registerParameter(self.resnet)
} else {
  registerParameter(self.rnn)
}
```

However, with a "register parameter" function, it's not clear what the parameter aggregate representation would be. Since actual registered parameters may be conditional on based runtime values, a runtime "parameters" data structure may be necessary, requiring much more compiler support. From a design perspective, the "register parameter" function is a type of metaprogramming and goes against the principles of Swift for TensorFlow.

For this particular example, a more robust solution would be to support enum conformance to `ParameterAggregate`/`Parameterized`, and to use an enum to represent the sub-model:

```swift
enum ResNetOrRNNParameters : ParameterAggregate {
  case resnet(ResNetModel)
  case rnn(RNNModel)
}

struct ToyParameters : ParameterAggregate {
  var resnetOrRnn: ResNetOrRNNParameters

  init(resnet: ResNetModel, rnn: RNNModel, useResNet: Bool) {
    resnetOrRnn = useResNet ? .resnet(resnet) : .rnn(rnn)
  }
}
```

This avoids the need for complex runtime support.

### Naming of `@TFParameter`

During early stages of the design, the parameter registration attribute was named `@parameter` instead of `@TFParameter`. However, we decided to use `@TFParameter` because "parameter" is a general and overloaded term, while the purpose of the attribute is domain-specific. `@TFParameter` makes it clear that the attribute is TensorFlow-specific and the naming is consistent with the `@IBOutlet` attribute used in iOS development.

### Macro-based parameter update (works with heterogeneous parameters)

Since `ParameterAggregate` types are structs and not an `Array`-like collection, it's not possible to use a regular for-loop to iterate over each parameter. We need some way to jointly iterate over the members of two structs of the same type (parameters and gradients) to perform parameter update.

Swift doesn't directly support zipping or iterating over struct members, so we can introduce an ad-hoc, specific language feature to meet our needs. The most specific/reduced language feature is a macro like `#forZippedParameters` which jointly zips and iterates over the members of two instances of a `ParameterAggregate` type, takes a trailing closure with two arguments, and expands to straight-line code:

```swift
struct Parameters : ParameterAggregate {
  var weight: Tensor<Float>
  var bias: Float
}

func optimize(parameters: inout Parameters, gradients: Parameters) {
  #forZippedParameters(parameters, gradients) {
    // In Swift, $0 and $1 are default closure argument names.
    $0 -= learningRate * $1
  }

  // The macro expands to the following:
  // parameters.weight -= learningRate * gradients.weight
  // parameters.bias -= learningRate * gradients.bias
}
```

Macro expansion for `#forZippedParameters` would occur before type-checking, so arbitrary code can be written in the trailing closure and get type-checked/resolved to concrete functions later. Any operations that work in straight-line code naturally work within the macro trailing closure:

```swift
// Works just like #forZippedParameters, but the trailing closure takes
// only one argument.
#forParameters(parameters) {
  print($0)
}
```

Swift does not yet have a hygienic macro system, which is a strong reason to avoid this design. It makes more sense to use compiler synthesis to implement the `func update(withGradients:_:)` protocol requirement since there's existing infrastructure to do that. It is possible to iterate over `ParameterAggregate` members and perform arbitrary accesses/mutation using key paths. By synthesizing an `allKeyPaths` static property for `ParameterAggregate` types, we can achieve most of the functionality of macros. [Read above](#complex-iteration-and-mutation-of-parameters-implementation-in-progress) for more details on the `allKeyPaths` synthesis design.
