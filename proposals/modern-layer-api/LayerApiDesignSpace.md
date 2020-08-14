# Layer API Design Space
## Overview
This document describes the high-level requirements and tradeoffs for a successful layer API design. It also walks through a couple conceptual approaches for API designs.

## Definitions
Neural Network - collection of weight values and a differentiable execution function

Layer - a differentiable function from (weights & input) to output, and a default function from hyperparameters to weights

Initialization Function - an optionally differentiable function mapping hyperparameters of a layer to a new instance of the weights or an existing weight store that has been mutated

Model - a mapping of a set of layers to a set of weight instances (bipartite; many-to-many)

## API Requirements
### Layer Composition
- Any layer, combination of layers, or trained model, should be usable as a layer in another model
- Scales to complex architectures, no need to rewrite the model to use a different API for advanced graph types
- No boilerplate:
    - No duplicate shapes
    - No duplicate input/output/scalar types (use type inference)
    - No redundant definition of weights and execution in default use cases

### Complex Architectures
- Skip-connections (use results of a layer multiple times)
- Shared layers (reuse weights multiple times, usually but not always with the same execution function but at different points of the graph)
- Support dynamic architectures, with generated layers and connections based on runtime configuration
    - Also support reconfiguration of models to use different hyperparameters at runtime

### State Management
- Weight access should be type-safe (no casting into the specific type)
- All weights should have associated names (variables, subscripts) and can use those names to access the current value
- Weights should be groupable for advanced optimizers (e.g. that use multiple learning rates) or partially "freezing" a model.
- Weights should be loadable from checkpoint files and support mapping weights from equivalent models
- Weight manipulation should be handled in a value-semantic way to prevent unexpected changes

### Execution Debugging
- Access to the values of intermediate tensors within the graph (inputs/outputs to layers)
    - Not stored by default, should be opt-in
- Insert debugging “layers” (e.g. that print out their input, or compute arbitrary other data-dependent information)
- Display the final model architecture in a graphical format

### Type-Safety
- No stringly-typed APIs
    - access to weights/intermediate tensors must be type-safe
- Rank-safe computation - track the number of dimensions of data
- Track the meaning of each channel (differentiate “CHW” vs “HWC” images)
- All other opportunities that are reasonably accessible

## Design Approaches
### Weights vs. Execution vs. Layers
One of the key insights resulting from our discussions was the separation between weights and model execution. In the current S4TF layer API, these are combined by defining layers as stateful functions which both capture the current weight values and define how the layer should be applied to input data. While this works well for simple systems that have a bijection between weights and execution functions, this is harder to adapt to systems that require the same layer with the same weights to be applied at multiple locations in the model (layer sharing). Implementing such architectures with packaged weights and execution results in referential semantics since multiple nodes in the graph would need to refer to the same underlying layer.

If we take a more functional approach, however, where weights do not make up the state of a function but instead are just an additional parameter for execution, this becomes more straightforward to handle. Instead of having to refer to a shared mutable state of a specific layer, the execution functions instead take the entire set of weights of the model and use the weights that are relevant to the current node. As a result, we effectively bubble up individual weights to the model level and eliminate the referential semantics needed when execution functions are tied to mutable state.

When separating weights from execution, however, we must be careful to not introduce boilerplate that forces duplicate definitions of weights and execution when one can be inferred from the other. Although layers are not a core component of the final model, they can exist as helpers that associate weights with default execution functions in order to eliminate boilerplate.

### Explicit Graphs vs Layers as Tensors

In our prototypes for layer APIs, we settled on two primary strategies for combining layers into more complex architectures: building an explicit graph or inferring the graph from layer dependencies.

In the first strategy, the user directly builds the entire graph in a way that requires no additional computation to determine the dependents of any layer. This requires the user to be aware of both incoming and outgoing edges from every layer “node” when constructing the model, but makes it easy to get high performance since there is a direct mapping from the composed layers to the weights and functions to execute. For example, when implementing a skip connection, the user would need to specify both a “fan-out” for the layer whose results will be used along multiple paths as well as a “fan-in” to combine the results.

For a simpler user experience, we can infer the graph based on dependencies, which eliminates the need to specify the “fan-out” of skip connections since we can detect layers that have multiple dependents. When designing models with this style, every layer tracks its dependencies. In this way, users can manipulate layers just like lazy tensors, since they accumulate a trace of dependencies and can be used as dependencies of other layers to define connections.
