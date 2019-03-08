# Differentiable types

Richard Wei, Dan Zheng

March 2019

## Preface

Mathematically speaking, only functions are "differentiable": only functions have derivatives and can be differentiated. In this document, the terminology "differentiable types" is used as a shorthand for "types that can be used as arguments and results of differentiable functions". This notion is important because not all types are "differentiable" in this sense. For example, types representing real numbers and vector spaces are "differentiable", but strings and integers are not.

## Introduction

Elementary calculus defines differentiation on real numbers: most people are familiar with this definition of "differentiation". However, differentiation is defined for many concepts across different branches of mathematics:
* Scalar differentiation: differentiation on real numbers. This is taught in introductory calculus.
* [Vector calculus]: a branch of mathematics that involves differentiation of vector fields.
* [Differential geometry]: a branch of mathematics that involves differentiation of functions over manifolds.

In Swift, we want to build a general system for differentiation that can represent all of these cases. Differentiation should not be limited to functions over specific types (e.g. functions over floating-point numbers); it should also work with functions whose parameters/result are custom types.

This raises some questions: what kind of types can be used as arguments and results of differentiable functions, and how can we generalize them using a protocol?

## Design overview

The `Differentiable` protocol generalizes all types that can be used as arguments and results of differentiable functions.

The compiler can automatically provide default implementations of `Differentiable` protocol requirements for struct types whose stored properties all conform to `Differentiable`.

Here are some examples:

```swift
struct Vector: Differentiable, VectorNumeric {
    // The compiler synthesizes all `Differentiable` protocol requirements
    // when all stored properties conform to `Differentiable`.
    var x, y, z: Float
}

// Differential operators like `gradient(at:in:)` just work!
let v = Vector(x: 1, y: 2, z: 3)
let 𝛁v = gradient(at: v) { v in (v + v).x }

print(𝛁v)
// Vector(x: 2.0, y: 0.0, z: 0.0)
```

A `Differentiable`-conforming type may have stored properties that are not meant to have a derivative with respect to `self`. Use the `@noDerivative` attribute to mark those properties; they will not have a corresponding entry in the synthesized `TangentVector`, `CotangentVector`, and `AllDifferentiableVariables` struct types.

Here’s an example deep learning layer with some `@noDerivative` properties:

```swift
struct DenseLayer : Differentiable {
    // These properties should have derivative values.
    var weight: Tensor<Float>
    var bias: Tensor<Float>

    // These auxiliary properties should not have derivative values.
    // Thus, they are marked with `@noDerivative`.
    //
    // `@noDerivative` properties do not have a corresponding entry
    // in synthesized associated struct types.
    @noDerivative var useBias: Bool = true
    @noDerivative var previousWeight: Tensor<Float> = Tensor(0)

    init(weight: Tensor<Float>, bias: Tensor<Float>) {
        self.weight = weight
        self.bias = bias
    }

    // The compiler synthesizes all `Differentiable` protocol requirements,
    // adding only properties not marked with `@noDerivative` to associated
    // tangent space types.

    func applied(to input: Tensor<Float>) -> Tensor<Float> {
        return matmul(input, weight) + bias
    }
}

// Differential operators like `gradient(at:in:)` just work!
let dense = DenseLayer(weight: [[1, 1], [1, 1]], bias: [0, 0])
let 𝛁dense = gradient(at: dense) { dense in dense.applied(to: [[3, 3]]).sum() }

dump(𝛁dense)
// ▿ DenseLayer.AllDifferentiableVariables
//   - weight: [[3.0, 3.0], [3.0, 3.0]]
//   - bias: [1.0, 1.0]
```

## Protocol details

Here is the full `Differentiable` protocol definition. More explanation is provided below.

```swift
/// A type that mathematically represents a differentiable manifold whose
/// tangent spaces are finite-dimensional.
public protocol Differentiable {
    /// The tangent bundle of this differentiable manifold.
    associatedtype TangentVector : AdditiveArithmetic & Differentiable
        where TangentVector.TangentVector == TangentVector,
              TangentVector.CotangentVector == CotangentVector,
              TangentVector.AllDifferentiableVariables == TangentVector
    /// The cotangent bundle of this differentiable manifold.
    associatedtype CotangentVector : AdditiveArithmetic & Differentiable
        where CotangentVector.TangentVector == CotangentVector,
              CotangentVector.CotangentVector == TangentVector,
              CotangentVector.AllDifferentiableVariables == CotangentVector
    /// The type of all differentiable variables in this type.
    associatedtype AllDifferentiableVariables : Differentiable
        where AllDifferentiableVariables.AllDifferentiableVariables ==
                  AllDifferentiableVariables,
              AllDifferentiableVariables.TangentVector == TangentVector,
              AllDifferentiableVariables.CotangentVector == CotangentVector

    /// All differentiable variables in this type.
    var allDifferentiableVariables: AllDifferentiableVariables { get }

    /// Returns `self` moved along the value space towards the given tangent
    /// vector. In Riemannian geometry (mathematics), this represents an
    /// exponential map.
    func moved(along direction: TangentVector) -> Self

    /// Convert a cotangent vector to its corresponding tangent vector.
    func tangentVector(from cotangent: CotangentVector) -> TangentVector
}
```

Mathematically, `Differentiable` represents a differentiable manifold: this is a technical term for smooth-surfaced objects like spheres and generalizes types that are compatible with differentiation, like `Float`, `Double`, `Tensor`, and `SIMD4<Float>`. Here's an example of a sphere as a differentiable manifold:

<p align="center">
  <img src="https://upload.wikimedia.org/wikipedia/commons/3/37/Pushforward.svg" align=center>
  <br>
  <sub>Image from https://en.wikipedia.org/wiki/Pushforward_(differential) showing two differentiable manifolds: M and N</sub>
</p>

This definition comes from differential geometry and is quite technical, and not all details are relevant for most use cases.

Here are the important requirements:
* `associatedtype TangentVector`: represents the type of directional derivatives computed via forward-mode differentiation.
* `associatedtype CotangentVector`: represents the type of gradient values computed via reverse-mode differentiation.
* `CotangentVector` types are used and produced by differential operators like `gradient` and `pullback`.
* `var allDifferentiableVariables: AllDifferentiableVariables`: represents all differentiable variables in an instance of the conforming type, where `AllDifferentiableVariables` is the type of all differentiable variables.
  * The motivation/design behind this is related to key path iteration .
* `TangentVector`, `CotangentVector`, and `AllDifferentiableVariables` are closely related.
  * All three associated types must themselves conform to `Differentiable`.
  * The `Differentiable` protocol associated types of the associated types themselves are defined to be mathematically correct.
    * `Foo.TangentVector.TangentVector` is `Foo.TangentVector` itself.
    * `Foo.CotangentVector.TangentVector` is `Foo.CotangentVector` itself.
    * `Foo.TangentVector.CotangentVector` is `Foo.CotangentVector`.
    * `Foo.CotangentVector.CotangentVector` is `Foo.TangentVector`.
    * `Foo.AllDifferentiableVariables` has the same `TangentVector` and `CotangentVector` as `Foo`.
  * Additionally, `TangentVector` and  `CotangentVector` must conform to `AdditiveArithmetic`, so that they can be zero-initialized and accumulated via addition. These are necessary to perform the chain rule of differentiation.
* Manifold operations.
  * These currently involve `func tangentVector(from cotangent: CotangentVector)` and `func moved(along cotangent: CotangentVector`). These operations can be useful for implementing manifold-related algorithms, like optimization on manifolds, but are not relevant for simple differentiation use cases.

The standard library defines conformances to the `Differentiable` protocol for `Float` and `Double`, as well as a conditional conformance for `Tensor`:

```swift
extension Float: Differentiable {
    public typealias TangentVector = Float
    public typealias CotangentVector = Float
    public typealias AllDifferentiableVariables = Float
}
// The conformance for `Double` is defined similarly.

extension Tensor: Differentiable where Scalar : TensorFlowFloatingPoint {
    public typealias TangentVector = Tensor
    public typealias CotangentVector = Tensor
    public typealias AllDifferentiableVariables = Tensor
}
```

## Compiler-synthesized implementations

As shown above, the compiler automatically synthesizes implementations of `Differentiable` requirements for struct types.

Here are the current conditions for synthesis:
* The type must declare a conformance to `Differentiable`, either on the type declaration or on an extension.
* The conforming type must be a struct type.
* All stored properties of the conforming type must either conform to `Differentiable` or be marked with the `@noDerivative` attribute.

The synthesis behavior is explained below.

### Associated type synthesis

Here are the synthesis rules for the three `Differentiable` associated types: `TangentVector`, `CotangentVector`, and `AllDifferentiableVariables`.

Let "differentiation properties" refer to all stored properties of the conforming type that are not marked with `@noDerivative`. These stored properties are guaranteed by the synthesis condition to all conform to `Differentiable`.

The synthesis rules are:
* Set associated types to `Self`, if possible.
  * If the conforming type conforms to `AdditiveArithmetic`, and no `@noDerivative` stored properties exist, and all stored properties satisfy `Self == Self.TangentVector == Self.CotangentVector == Self.AllDifferentiableVariables`, then all associated types can be set to typealiases of `Self`.
* Synthesize a single `AllDifferentiableVariables` member struct. Set `TangentVector` and `CotangentVector` to `AllDifferentiableVariables` if possible; otherwise synthesize more member structs.
  * Regarding member struct synthesis: for each "differentiation property" in the conforming type, a corresponding stored property is synthesized in the member structs, with type equal to the property’s associated type.
  * `TangentVector` and `CotangentVector` can be set to `AllDifferentiableVariables` if all differentiation properties satisfy `Self.TangentVector == Self.CotangentVector == Self.AllDifferentiableVariables`.

A memberwise initializer is synthesized for the conforming type itself, in addition to all associated structs. This is important for differentiating struct properties accesses and synthesizing manifold operation requirements.

### Synthesis for other requirements

`var allDifferentiableVariables: AllDifferentiableVariables` is synthesized as a computed property that mirrors the differentiation properties of the conforming type.

It is always synthesized with a getter.
It is synthesized with a setter only when all differentiation properties are mutable and themselves all have mutable `allDifferentiableVariables` properties.

Examples:
```swift
// Example when `AllDifferentiableVariables == Self`.
var allDifferentiableVariables: AllDifferentiableVariables {
    get { return self }
    set { return newValue }
}

// Example when `AllDifferentiableVariables != Self`.
var allDifferentiableVariables: AllDifferentiableVariables {
    get { return AllDifferentiableVariables(x: x, y: y, ...) }
    set { x = newValue.x; y = newValue.y }
}
```

Manifold operations are synthesized to forward the same operation defined on differentiation properties:

```swift
// Let `Foo` be the name of the type conforming to `Differentiable`.
func tangentVector(from cotangent: CotangentVector) -> TangentVector {
    return TangentVector(x: x.tangentVector(from: cotangent.x), ...)
}
func moved(along tangent: TangentVector) -> Foo {
    return Foo(x: x.moved(along: tangent.x), ...)
}

// Potential shortcuts for synthesis:
// When `TangentVector == CotangentVector`:
func tangentVector(from cotangent: CotangentVector) -> TangentVector {
    return cotangent
}
// When `Foo == TangentVector`:
func moved(along tangent: TangentVector) -> Foo {
    return tangent
}
```

## Example

Let’s look at a complete example:

```swift
struct GenericWrapper<T: Differentiable, U: Differentiable>: Differentiable {
    // `x` and `y` are the "differentiation properties".
    var x: T
    var y: U
    @noDerivative var customFlag: Bool
    @noDerivative var helperVariable: T

    // The compiler synthesizes:
    //
    // struct TangentVector : Differentiable, AdditiveArithmetic {
    //   var x: T.TangentVector
    //   var y: U.TangentVector
    //   ...
    // }
    // struct CotangentVector : Differentiable, AdditiveArithmetic {
    //   var x: T.CotangentVector
    //   var y: U.CotangentVector
    //   ...
    // }
    // struct AllDifferentiableVariables : Differentiable {
    //   var x: T.AllDifferentiableVariables
    //   var y: U.AllDifferentiableVariables
    //   ...
    // }
    // var allDifferentiableVariables: AllDifferentiableVariables {
    //   get { return AllDifferentiableVariables(weight: weight, bias: bias) }
    //   set { weight = newValue.weight; bias = newValue.bias }
    // }
    // func tangentVector(from cotangent: CotangentVector) -> TangentVector {
    //     return TangentVector(x: x.tangentVector(from: cotangent.x),
    //                          y: y.tangentVector(from: cotangent.y))
    // }
    // func moved(along tangent: TangentVector) -> Foo {
    //     return GenericWrapper(x: x.moved(along: tangent.x)
    //                           y: y.moved(along: tangent.y))
    // }
}
```

## Acknowledgements

The authors would like to thank Casey Chu, Gordon Plotkin, Dougal Maclaurin, Matthew Johnson, Marc Rasi, and James Bradbury for their input to the design of the `Differentiable` protocol.

[vector calculus]: https://en.wikipedia.org/wiki/Vector_calculus
[differential geometry]: https://en.wikipedia.org/wiki/Differential_geometry
