# Layer API Prototypes
## Overview
This document describes the various prototypes implemented when exploring the design space for the new layer API. It explains the reasoning behind each design and analyzes the resulting user experience according to the design space [requirements](https://docs.google.com/document/d/1fWkbuGpGz_wRGtwUuwsX-IEVEly0kiAjBpxvcJDSODI/edit). Finally, we compare the two high-level design directions explored and propose possible directions for a complete API design.

## Explicit Graph API
In the first set of prototypes, we explored designs that have users explicitly define the computation graph of the neural network. This means that advanced features such as skip connections have special APIs rather than being deduced at runtime. We found that these implementations map more easily onto the existing layer API, but are less intuitive compared to the implicit graph designs when developing non-sequential models.

At this point in the design process, the layer type still represents a combination of weight instances and an execution function. While this doesn’t directly align with the separation of weight values from execution outlined in the design requirements, the prototypes implemented can be easily adjusted to align with the model by replacing layer instances with just the weights. In both systems the execution function is inferred separately so we do not depend on the original association.


### Staged (Auto)Layers
In order to enable automatic weight shape computation while still maintaining compatibility with the existing layer API, our first prototype used a staged model where users compose models with building blocks provided by the prototype but eventually build the “blueprint” into a realized model that conforms to the existing `Layer` type. In our system, every blueprint building block has a 1:1 pairing to a layer in the existing API, which makes the building process simple since it is just a recursive conversion of all building blocks into realized layers.

We can see the prototype in action with a snippet of a ResNet block-like model:

```swift
let residual = AutoFunction(fnShape: identity, fn: identity })

let convLayers =
  AutoConvBN(filterShape: (3, 3), outputChannels: filters, padding: .same)
    .then(AutoFunction(fnShape: identity, fn: relu))
    .then(AutoConvBN(filterShape: (3, 3), outputChannels: filters, padding: .same))

let residualPlusConv = AutoSplitMerge(
    layer1: residual, layer2: convLayers,
    mergeOutputShape: identity, mergeFn: { $0 + $1 }
)
```

#### Staged Building Blocks

To combine layers, the staging system provides a couple different building blocks. The most simple one is `.then`, which combines two layers in sequence. When `.then` is applied many times in succession, it effectively creates a cons-list of layers. This handles sequential models slightly better than the existing `Sequential` type, because there is no hardcoded limit on the number of layers to sequence.

Moving beyond simple sequential models, we offer three additional blocks for more complex models:
- SequentialMany - sequences a dynamic set of layers which all have the same type; useful for models like ResNet and VGG
- SplitMerge - passes the input through two different layers and combines the results with a user-defined functions; useful for skip connections
- Reuse - passes the input through layer A, then layer B, then layer A again where the layers at the beginning and end share the same weights

These make it possible to express more complex architectures without having to fall back to implementing custom layers.


#### Weight Keys
To support accessing weights during training in a typesafe manner, we developed weight keys, which are values that can be associated with a specific staged layer. Then, we can access the instantiated layer as a subscript of the built model.

```swift
let denseKey = AutoLayerKey<Dense>()

let modelBlueprint = ...
  .then(
    AutoDense(outputShape: 128).withKey(denseKey)
  )

var model = modelBlueprint.build(inputShape: ...)
// train model ...
print(model[denseKey].weights)
```

### Structural Sequential Layers
In parallel to the chaining approach for combining layers, we also explored using structural generic programming to automatically chain together layers that are defined as properties of a struct. This offers a much nicer alternative to weight keys since the properties can be directly used to access the instantiated layers. Through structural generic programming, we are effectively able to infer a `callAsFunction` implementation from just the properties of the struct, which satisfies the design requirement of eliminating redundancy between weight definitions and the execution function.


```swift
struct MyModel: SequentialLayer {
   typealias Scalar = Float
   public var conv = Conv2D(
     filterShape: (5, 5, 3, 6)
   )
   
   public var pool = MaxPool2D(
     poolSize: (2, 2), strides: (2, 2)
   )
   
   public var flatten = Flatten()
   
   public var dense = Dense(
     inputSize: 36 * 6, outputSize: 10
  )
}
```

While the prototype implemented conforms directly to `Layer`, this is challenging to implement with automatic weight shapes since the properties are initialized independently. To eliminate redundant shape definitions, a full implementation would likely need to use a staged approach as well. One prototype of staged structural models generates a hyperparameters type, which handles inferring the layer shapes to construct the original layer struct.

```swift
public struct MyModel: Structural, HParamInitLayer, SequentialLayer {
    var conv: Conv2D<Float>
    var flatten: Flatten<Float>
    var dense: Dense<Float>
}

// Usage:
func makeModel() -> MyModel {
    var hparams = MyModel.HParam()
    hparams.conv = .init(height: 3, width: 3, channels: 10)  // Fully typesafe!
    hparams.dense = .init(size: 10)

    return hparams.build(for: Tensor(zeros: [5, 28, 28, 1]))
}
```

One interesting aspect about this implementation is that automatically generating the `HParam` type means that the user is effectively defining the weights shape and structural generic programming infers the API to construct those weights. This is the reverse of the previous structural example, where users construct the layer definitions, from which the actual weights are inferred. This offers a nice solution to the weight access issue since the user-defined struct can be directly used to access weight values, but also introduces a bit of code duplication since the specification of hyperparameters happens in a separate function.

### Type-Safe Weight Initialization
This design enables a natural API for weight initialization that supports both automatic initialization with random values as well as loading weights from a pretrained model. We can split the API into two types: one that represents a staged layer without a specified weight initializer and one with an initializer set.

Layers with unspecified initializers can still be composed, but a strategy for initialization must be set before the weights are constructed. This enables users to choose between initializing a sub-model with pretrained weights or training the underlying layers starting from random weights.

```swift
let myModel = (
  AutoDense(...)
    .then(...).withWeightInitializer(.random)
).then(ResNet(...).withWeightsFrom(pretrainedWeights))
```

Because every value in the explicit graph design represents a subgraph of the final model, we can specify an initialization strategy for a large chunk of the graph at once instead of having to do it layer-by-layer. This is one interesting advantage over the tracing approach discussed later, because in the other design every intermediate value represents a path from the input to an intermediate node of the final graph and so a similar chunked initialization strategy does not fit as well.

### Key Takeaways
The staging model works well to separate shape computation from weight initialization, which makes it easy to implement automatically computed weights without introducing unnecessary mutability into layers. Non-staging approaches would require lazy initialization of weights, which complicates the composition system since an initialized layer cannot be used in another model with different shapes. Furthermore, this system ties weight instances to layers, which makes many features such as weight sharing more complicated.

While the explicit model offers a more lightweight wrapper around the existing APIs by expressing concepts like skip connections as custom layer types, the mental model requires users to predict how they will use the results of a layer when implementing skip connections since they must explicitly split the output and merge the resulting branches.

The key object approach is an interesting way to access weights in a type-safe manner without introducing structs. However, this strategy is difficult to scale to models that incorporate other models, since the inner model may not export weight keys that the user needs. Since models that use keys would still need to export all the keys in some package, we end up needing structs anyways and so it may be better to just use a structural approach from the beginning.

However, the structural approach for composing layers comes with its own challenges. While sequential models fit in easily since the order of layers can be determined from the order of properties, it is trickier to implement skip connections and other “parallel” architectures since some properties will not be part of the regular sequential path. In this case, the structural approach offers a fallback of manually implementing `callAsFunction` to weave together the weights. As we discuss in the implicit graph section, tracing may offer a solution that does not force users to fall back to explicit execution functions even when more complex architectures are involved.


## Implicit Graph API
As we developed the explicit graph APIs, we realized that the model for concepts like skip connections is quite hard to grasp, because with an explicit graph the user has to manually split and merge, even though the split can be inferred from common dependencies. In order to improve the user experience when developing these complex models, we developed an implicit graph design.


### Layers as Tensors
With implicit graphs, the model building code mirrors the implementation of `callAsFunction` for a traditional layer. This results in a trace of the dependents of each node in the graph, which we can process after the model is composed to build a classic layer instance. From the perspective of the user, this results in layers being manipulable just like tensors. Every value in this API is effectively a node in the graph, with edges being transformations such as the application of a layer. Under this model, concepts such as skip connections are easy to implement since the user only needs to focus on the operation when merging nodes rather than worrying about which layer’s output will be used along multiple paths.

For example, a simple model with a skip connection looks like:

```swift
func myModel(input: AutoLayer<Float>) -> AutoLayer<Float> {
   let conv = conv2D(input: input,
     filterShape: (5, 5), outputShape: 6
   )
   
   let pool = maxPool2D(input: conv,
     poolSize: (2, 2), strides: (2, 2)
   )
   
   let flatten = flatten(input: pool)
   
   let preSkip = dense(input: flatten,
     outputSize: 10
  )

  return dense(input: preSkip,
     outputSize: 10
  ) + preSkip
}
```

This looks almost identical to the traditional `callAsFunction`, with the addition of hyperparameters that will be used in the default weight initialization.

### Sequential Chaining
In many situations, users want to chain many layers together. We offer a lightweight sequential API that enables users to do this without having deeply nested function calls.

```swift
func residualBlock(input: AutoLayer<Float>) {
  let convApplied =
    input
      .convBN(filterShape: (3, 3), outputChannels: filters, padding: .same)
      .relu()
      .convBN(filterShape: (3, 3), outputChannels: filters, padding: .same)
  
  return input + convApplied
}
```

### Structural Layers
As we noted in the explicit graph section, structural approaches make it easy to access individual weights but are unable to describe complex models elegantly within just the property definitions.  Through the implicit graph approach, we can improve this by using properties as interfaces to access weights but tracing to determine the connections between nodes.

```swift
struct ResidualBlock {
  let input: TracingNode
  let layerCount: Int

  lazy var firstConv = convBN(input: input, filterShape: (3, 3), outputChannels: filters, padding: .same)
  lazy var activated = relu(input: firstConv, …: layerCount)
  lazy var secondConv = convBN(input: activated, filterShape: (3, 3), outputChannels: filters, padding: .same)
  
  lazy var output = input + secondConv
}
```

This approach gets us the best of the structural and implicit graph approaches by giving users the flexibility to define complex architectures while automatically exposing the weights of the underlying layers.

### Key Takeaways
The biggest strength of the implicit graph API comes from the "layers-as-tensors" mental model, which makes it much easier to reason about concepts such as skip connections since the model building code mirrors what the `callAsFunction` would look like if it were manually implemented.

This system does come with some overhead, because there is more structure to be inferred at runtime so not as much optimization can be done ahead of time. Some approaches to improving performance included using a pull-based approach that builds up closures rather than the original push-based approach that requires computing a topological sort. Unfortunately, due to some AD limitations during prototyping, we were unable to evaluate the performance of the pull-based model.

Ergonomic sequential composition is a must-have for both the explicit and implicit designs, since sequential models are by far the most common type of model found today. It is important to ensure that these types of models are as easy to implement as possible, since even complex architectures involve sequential steps in their subgraphs.

Keyed weight (and intermediate tensor) access has a similar story to the explicit design. We can either use keys like explained for explicit graphs, or can use the structural approach. As discussed for explicit graphs, the structural approach seems to be the way to go because exporting keys will likely become quite tedious for complex models and introduces unnecessary boilerplate.

## Final Thoughts
The explicit and implicit graph designs cover a large range of options that each offer unique advantages and inherent limitations. In terms of the design requirements:

- Layer Composition (winner: explicit graphs)
    - Explicit Graphs - offer the most direct composition strategy with library-defined building blocks for combining layers in different architectures, also offers a good story for customizing weight initialization by setting the strategy for a large subgraph at once
    - Implicit Graphs - supports embedding subgraphs by regenerating their traces with an input node from the parent model, more difficult to specify weight initialization strategies since there is no clear way to reference a subgraph of the model
- Complex Architectures (winner: implicit graphs)
    - Explicit Graphs - supports concepts like skip connections, but requires the user to define the graph using the existing building blocks, which may be hard to reason about
    - Implicit Graphs - offers an intuitive approach to complex connections by having users effectively define a `callAsFunction`, which supports reusing values along multiple paths as well as dynamic architectures
- Weight Access / Execution Debugging (winner: tie)
    - As long as some structural approach is implemented, which exists for both designs, weight access and debugging is fairly straightforward
- Type-Safety (winner: tie)
    - Both models support encoding type-level features such as the rank of tensors and the scalar type

With these tradeoffs, we propose two potential design directions:

1. Focus on the implicit graph model, which has demonstrated its ability to succinctly represent both simple sequential models as well as complex ones with dynamically generated structure, but explore ways to provide better ways to specify weight initialization. The most promising way to improve this is through the structural API. The most common points of specification are at the individual layers and at the model-level. Individual layers are already easy to handle since the initializer can be thought of as a sibling of hyperparameters, and the structural API could expose some way to specify the initialization strategy for an entire model.
2. Given the split of winners between composition and support for complex architectures, explore a fused approach where the explicit model is used for high-level sequencing, but the implicit model is used for defining complex architectures. As long as implicit models can use explicit submodels and vice-versa, this should not introduce the issue of having to rewrite code to introduce advanced concepts. However, we must be careful to ensure that type information is not lost when going from one approach to the other in order to maintain support for features like weight access. In addition, a danger of this approach is that there may be two types of structural models, which could become quite confusing to users.
