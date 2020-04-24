# Differentiable functions and differentiation APIs

[Richard Wei], [Dan Zheng], [Marc Rasi], [Parker Schuh]

Last updated: March 2019

> #### Experimental
>
> Automatic differentiation and differentiable programming are being incubated in the
> ['tensorflow' branch of apple/swift](https://github.com/apple/swift/tree/tensorflow)
> and released as part of the
> [Swift for TensorFlow toolchains](https://github.com/tensorflow/swift#getting-started),
> which you can play with. The authors will propose this feature through
> [Swift Evolution](https://forums.swift.org/c/evolution) in 2019.

## Introduction

Swift supports differentiable functions as part of the language. The
`@differentiable` attribute appears in two locations in Swift syntax: as an
annotation on function types and as an annotation on function declarations (and
other similar declarations). This document explains the meaning of these
annotations.

## `@differentiable` function type attribute

### Basics

In Swift, function types can have attributes. When a function type is annotated
with `@differentiable`, Swift guarantees that all values of that function type
can be differentiated.

`@differentiable` functions can be called like normal functions, or be passed to
APIs that take `@differentiable` functions, like [`gradient(of:)`]. The binary
representation of a `@differentiable` function is a special data structure
containing the original function along with extra information required for
computing its derivatives. `@differentiable` functions are a part of Swift's
type system. Most notably, they are used by differentiation APIs in the standard
library. Here are some examples demonstrating differentiation APIs:

```swift
func square(_ x: Float) -> Float {
    return x * x
}
let x: Float = 3.0

// Free function examples.

// Computes the gradient of `square` at `x`.
print(gradient(at: x, in: square)) // 6.0
// Computes the gradient of `square`, then applies it to `x`.
print(gradient(of: square)(x)) // 6.0
// Computes the value and gradient of `square` at `x`.
print(valueWithGradient(at: x, in: square)) // (value: 9.0, gradient: 6.0)

// Method examples.

// Computes the gradient of `square` at `x`.
print(x.gradient(in: square)) // 6.0
// Computes the value and gradient of `square` at `x`.
print(x.valueWithGradient(in: square)) // (value: 9.0, gradient: 6.0)
```

Here's a list of differentiation APIs currently provided by the standard library:

| Differentiation APIs  | Description                                                                                                                                                      |
|-----------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [`valueWithPullback(at:in:)`] <br/> [`valueWithPullback(at:_:in:)`] | Returns original result and pullback function. <br/> **Important note: this is the core differentiation API. All other APIs are defined in terms of `valueWithPullback`.** |
| [`pullback(at:in:)`] <br/> [`pullback(at:_:in:)`] | Returns pullback function. |
| [`gradient(at:in:)`] <br/> [`gradient(at:_:in:)`] | Returns partial derivatives with respect to arguments. |
| [`valueWithGradient(at:in:)`] <br/> [`valueWithGradient(at:_:in:)`] | Returns original result and partial derivatives with respect to arguments. |
| [`gradient(of:)`] <br/> [`gradient(of:)` (arity 2)] | Returns gradient function, taking original arguments and returning and partial derivatives with respect to arguments. |
| [`valueWithGradient(of:)`] <br/> [`valueWithGradient(of:)` (arity 2)] | Returns function taking original arguments and returning original result and partial derivatives with respect to arguments. |

### Constructing `@differentiable` functions

A value with a non-differentiable function type can be implicitly converted to
one with a corresponding `@differentiable` function type. In fact, this is what
happened in the example above:

```swift
// `square` has type `(Float) -> Float`.
func square(_ x: Float) -> Float {
    return x * x
}
let x: Float = 3.0

// The second argument of `gradient(at:in:)` has type `@differentiable (Float) -> Float`.
// When `square` is passed to `gradient(at:in:)`, it is implicitly converted to a value with the
// `@differentiable` type.
print(gradient(at: x, in: square)) // 6.0
```

The implicit conversion from a value with type `(T) -> U` to a value with type
`@differentiable (T) -> U` actually triggers differentiation by the compiler.
Thus, differentiation is type-driven.

If differentiation succeeds, the `@differentiable (T) -> U` value is
constructed. If differentiation fails, the compiler emits a compile-time error:

```swift
let add: @differentiable (Float, Float) -> Float = { x, y in
    // The `Int` initializer call below is non-differentiable.
    Float(Int(x + y))
}
```

```console
test.swift:1:52: error: function is not differentiable
let add: @differentiable (Float, Float) -> Float = { x, y in
                                                   ^~~~~~~~~
test.swift:2:11: note: cannot differentiate through a non-differentiable result; do you want to add '.withoutDerivative()'?
    Float(Int(x + y))
          ^
```

There are a few reasons why differentiation can fail:
* The function to differentiate contains computation, from parameters to result,
  that cannot be differentiated.
* The function to differentiate is opaque, i.e. it is a function parameter with
  a non-`@differentiable` function type.
* The function to differentiate is defined in another module, and is neither
  marked with `@differentiable` nor has a registered derivative.
* The function to differentiate uses [control
  flow](https://docs.swift.org/swift-book/LanguageGuide/ControlFlow.html)
  (if-statements, switch-statements, loops, etc). This restriction will be
  lifted soon.
  
## `@differentiable` declaration attribute

### Basics

The `@differentiable` attribute can also be applied to function declarations.
`@differentiable` marks a function as being differentiable with respect to some
parameters (the varying parameters, explained below). `@differentiable` requires
the types of the varying parameters and the function result type to all conform
to the `Differentiable` protocol.

This annotation does not change the function declaration to have a
`@differentiable` function type; instead, it tells the compiler to differentiate
the function when compiling its containing file. If differentiation succeeds,
the function can be coerced to have a `@differentiable` function type anytime;
if not, a compile-time error will be produced.

You may wonder about the purpose of the `@differentiable` declaration attribute,
given that non-differentiable functions can implicitly be converted to
`@differentiable` functions, as mentioned above. The main reason is that the
`@differentiable` declaration attribute is a contract for differentiability: if
a function is declared with `@differentiable` and it compiles, then it is always
guaranteed to be differentiable, even in other modules when the function is
public. On the other hand, if a function is not declared with `@differentiable`,
then differentiation of the function in other modules will fail.

This is why floating-point operations in the standard library are declared with
`@differentiable`:

```swift
extension Float {
    @differentiable
    public static func + (lhs: Float, rhs: Float) -> Float { ... }
}
```

Besides function declarations, there are a few other function-like declarations
that can be marked with `@differentiable`:
- Stored and computed properties.
  - This requires both the type defining the property
    and the type of the property to conform to `Differentiable`.
  - Property getters are differentiable with respect to `self`.
- Initializers.
  - This requires the type defining the initializer to conform to
    `Differentiable`.

For instance methods defined on types that conform to `Differentiable`, the
`self` property can be marked as a varying parameter. Derivatives of these
methods return the partial derivative with respect to `self`. For these methods,
`@differentiable` infers `self` as a varying parameter by default.

```swift
struct Vector: Differentiable {
    var x, y: Float

    // Differentiable computed property.
    @differentiable // Implicitly: @differentiable(wrt: self)
    var magnitude: Float {
        return (x * x + y * y).squareRoot()
    }

    // Differentiable initializer.
    @differentiable // Implicitly: @differentiable(wrt: (x, y))
    init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
}

let v = Vector(x: 2, y: 2)
print(v.magnitude)
// 2.828427
print(gradient(at: v) { v in v.magnitude })
// Vector(x: 0.70710677, y: 0.70710677)
```

### Differentiating with respect to

Mathematically, let "varying parameters" refer to the parameters (i.e.
independent variables) of a differentiable function whose partial derivatives
are computed by the function's derivative.

By default, the `@differentiable` attribute infers all function parameters that
conform to `Differentiable` to be the varying parameters. However, this is not
always desirable, because differentiating with respect to a subset of parameters
is computationally less expensive. To declare functions as differentiable with
respect to a subset of parameters, explicitly specify the varying parameters
using the `@differentiable(wrt: ...)` syntax.

Here's an example of a 2-D convolution operation, adapted from the TensorFlow
library. The convolution input and filter are the varying parameters; strides
and padding are not.

```swift
@differentiable(wrt: (input, filter))
func conv2d(input: Tensor<Float>, filter: Tensor<Float>, strides: (Int, Int), padding: Padding) {
    ...
}
```

Functions can have multiple `@differentiable` attributes with differentiable
`wrt` parameter lists. If a protocol requirement is marked with
`@differentiable`, all implementations of the requirement are required to
specify the same attribute. This enables generic code using differentiation
defined in terms of protocol requirements.

Here is an example of a neural network `Layer` protocol that defines a
`@differentiable` method called `call(_:)`. As shown, the `call(_:)`
method can be differentiated in a `Layer` protocol extension, even though it is
not a concrete method.

```swift
import TensorFlow

/// A neural network layer.
protocol Layer: Differentiable {
    /// The input type of the layer.
    associatedtype Input: Differentiable
    /// The output type of the layer.
    associatedtype Output: Differentiable
    /// Returns the output obtained from applying the layer to the given input.
    @differentiable
    func call(_ input: Input) -> Output
}

extension Layer {
    /// Returns the inference output and the backpropagation function obtained from applying the
    /// layer to the given input.
    ///
    /// - Parameter input: The input to the layer.
    /// - Returns: A tuple containing the output and the backpropagation function. The
    ///   backpropagation function (a.k.a. backpropagator) takes a direction vector and returns the
    ///   gradients at the layer and at the input, respectively.
    func appliedForBackpropagation(to input: Input)
        -> (output: Output,
            backpropagator: (_ direction: Output.TangentVector)
                -> (layerGradient: TangentVector, inputGradient: Input.TangentVector)) {
        let (out, pullback) = valueWithPullback(at: input) { layer, input in
            return layer(input)
        }
        return (out, pullback)
    }
}

// Example neural network layer.
struct DenseLayer: Layer {
    var weight: Tensor<Float>
    var bias: Tensor<Float>

    @differentiable
    func call(_ input: Tensor<Float>) -> Tensor<Float> {
        return matmul(input, weight) + bias
    }
}

// Example usage of `appliedForBackpropagation(to:)`.
let dense = DenseLayer(weight: [[1, 1], [1, 1]], bias: [1, 1])
let input: Tensor<Float> = [[3, 3]]
let seed: Tensor<Float> = [[1, 1]]

let (output, backprop) = dense.appliedForBackpropagation(to: input)
let (𝛁dense, 𝛁input) = backprop(seed)

dump(𝛁dense)
// ▿ DenseLayer.AllDifferentiableVariables
//   - weight: [[3.0, 3.0], [3.0, 3.0]]
//   - bias: [1.0, 1.0]
print(𝛁input)
// [[2.0, 2.0]]
```

## Providing a custom derivative

Use the `@differentiating` attribute to mark a function as a custom derivative
for another function. This is useful for registering derivatives for functions
that cannot be differentiated by traversing the function body, typically
primitive math library operators.

*Note: currently, the `@differentiating` attribute can only be used to define
derivatives for functions in the same module. We plan to lift this limitation
soon so that derivatives can be retroactively declared for functions in other
modules - [see this forum
discussion](https://forums.swift.org/t/help-needed-with-retroactive-differentiability/19927)
for more information.*

```swift
import Foundation

func sillyExp(_ x: Float) -> Float {
    let 𝑒 = Float(M_E)
    print("Taking 𝑒(\(𝑒)) to the power of \(x)!")
    return pow(𝑒, x)
}

@differentiating(sillyExp)
func sillyDerivative(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
    let y = sillyExp(x)
    return (value: y, pullback: { v in v * y })
}

print(gradient(of: sillyExp)(3))
// Taking 𝑒(2.7182817) to the power of 3.0!
// 20.085535
```

## Constructing a `@differentiable` function from a derivative

Given a function and its derivative, it is possible to construct a
`@differentiable` version of the function using the
[`differentiableFunction(from:)`] API defined in the standard library.

Here's an example:
```swift
let multiply: @differentiable (Float, Float) -> Float =
    differentiableFunction(from: { x, y in (value: x * y, pullback: { v in (v * y, v * x) }) })
```

Internally, `differentiableFunction(from:)` is defined just using the
`@differentiating` attribute - there's no extra magic:

```swift
/// Returns a differentiable function given its derivative.
public func differentiableFunction<T: Differentiable, R: Differentiable>(
    from vjp: @escaping (T) -> (value: R, pullback: (R.TangentVector) -> T.TangentVector)
) -> @differentiable (T) -> R {
    func original(_ x: T) -> R {
        return vjp(x).value
    }
    @differentiating(original)
    func derivative(_ x: T) -> (value: R, pullback: (R.TangentVector) -> T.TangentVector) {
        return vjp(x)
    }
    return original
}
```

## `@differentiable` functions and automatic differentiation

[Automatic differentiation] is the technique used by the compiler to
automatically compute function derivatives. This document does not go into
detail about the automatic differentiation algorithm - but with an understanding
of `@differentiable` functions and differentiation APIs, one can get a glimpse
of how automatic differentiation works.

*Note: automatic differentiation is an implementation detail in the compiler
that enables differentiation. `@differentiable` functions and differentiation
APIs are the important, visible features to understand.*

The key differentiation API is the [`valueWithPullback(at:in:)`] function, which
takes a `@differentiable` function and arguments and returns two things: the
result of the function when applied to arguments, and a backpropagation function
called a "pullback", which takes a direction vector (usually the partial
derivative w.r.t. the original result) and returns the directional gradient
w.r.t. the varying parameters.

Let's consider the following function `foo`:

```swift
func foo(_ x: Float) -> Float {
    let double = x + x
    let result = double * double
    return result
}
```

Conceptually, here's how the compiler computes the `value` and the `pullback`
for `foo`:

```swift
func fooValueWithPullback(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
    // Replace function calls in `foo` with calls to `valueWithPullback`.
    // Keep track of pullbacks and use them to compute pullback of `foo`.
    let (double, doublePullback) =
        valueWithPullback(at: x, x, in: (+) as @differentiable (Float, Float) -> Float)
    let (result, resultPullback) =
        valueWithPullback(at: double, double, in: (*) as @differentiable (Float, Float) -> Float)
    let pullback: (Float) -> Float = { v in
        let (𝛁result1, 𝛁result2) = resultPullback(v)
        let (𝛁double1, 𝛁double2) = doublePullback(𝛁result1 + 𝛁result2)
        return 𝛁double1 + 𝛁double2
    }
    return (value: result, pullback: pullback)
}

// Test.
let x: Float = 3.0
let (result, pullback) = fooValueWithPullback(x)
print(result) // 36.0
print(pullback(1)) // 24.0

// Test the real `valueWithPullback` function.
do {
    let (result, pullback) = valueWithPullback(at: x, in: foo)
    print(result) // 36.0
    print(pullback(1)) // 24.0
}
```

All other differentiation APIs are defined in terms of
[`valueWithPullback(at:in:)`]. For example, here's how [`gradient(at:in:)`] is
defined:

```swift
// `gradient` returns the partial derivative with respect to varying parameters for scalar-result
// functions. It simply returns `pullback(1)`.
func gradient<T, R>(
    at x: T, in f: @differentiable (T) -> R
) -> T.TangentVector
    where T: Differentiable, R: FloatingPoint & Differentiable, R.TangentVector == R
{
    let (value, pullback) = valueWithPullback(at: x, in: f)
    return pullback(R(1))
}

print(gradient(at: x, in: foo)) // 24.0
```

You can find [the implementation of
`gradient(at:in:)`](https://github.com/apple/swift/blob/6e20cf1d2746435d879ccfeee9713aa7a32e1081/stdlib/public/core/AutoDiff.swift#L467)
in the standard library.

## Conclusion

Differentiable functions are represented in Swift's type system as
`@differentiable` function types. With this abstraction, it's possible to
implement custom differentiation APIs like custom derivatives, derivative
surgery, and checkpointing in just a few lines of Swift. Check out the [custom
differentiation
tutorial](https://github.com/tensorflow/swift/blob/master/docs/site/tutorials/custom_differentiation.ipynb)
for examples!

## Acknowledgements

The authors would like to thank Chris Lattner, Doug Gregor, John McCall, Slava
Pestov, Joe Groff, and Dmitri Gribenko for their input to the design of
differentiable functions and differentiation APIs.

[`valueWithPullback(at:in:)`]: https://github.com/apple/swift/blob/c1211a3f78992c89a3ab4d638c378c6f45ab8fe8/stdlib/public/core/AutoDiff.swift#L276
[`valueWithPullback(at:_:in:)`]: https://github.com/apple/swift/blob/c1211a3f78992c89a3ab4d638c378c6f45ab8fe8/stdlib/public/core/AutoDiff.swift#L283
[`pullback(at:in:)`]: https://github.com/apple/swift/blob/c1211a3f78992c89a3ab4d638c378c6f45ab8fe8/stdlib/public/core/AutoDiff.swift#L302
[`pullback(at:_:in:)`]: https://github.com/apple/swift/blob/c1211a3f78992c89a3ab4d638c378c6f45ab8fe8/stdlib/public/core/AutoDiff.swift#L309
[`gradient(at:in:)`]: https://github.com/apple/swift/blob/c1211a3f78992c89a3ab4d638c378c6f45ab8fe8/stdlib/public/core/AutoDiff.swift#L384
[`gradient(at:_:in:)`]: https://github.com/apple/swift/blob/c1211a3f78992c89a3ab4d638c378c6f45ab8fe8/stdlib/public/core/AutoDiff.swift#L392
[`valueWithGradient(at:in:)`]: https://github.com/apple/swift/blob/c1211a3f78992c89a3ab4d638c378c6f45ab8fe8/stdlib/public/core/AutoDiff.swift#L326
[`valueWithGradient(at:_:in:)`]: https://github.com/apple/swift/blob/c1211a3f78992c89a3ab4d638c378c6f45ab8fe8/stdlib/public/core/AutoDiff.swift#L335
[`gradient(of:)`]: https://github.com/apple/swift/blob/c1211a3f78992c89a3ab4d638c378c6f45ab8fe8/stdlib/public/core/AutoDiff.swift#L410
[`gradient(of:)` (arity 2)]: https://github.com/apple/swift/blob/c1211a3f78992c89a3ab4d638c378c6f45ab8fe8/stdlib/public/core/AutoDiff.swift#L418
[`valueWithGradient(of:)`]: https://github.com/apple/swift/blob/c1211a3f78992c89a3ab4d638c378c6f45ab8fe8/stdlib/public/core/AutoDiff.swift#L356
[`valueWithGradient(of:)` (arity 2)]: https://github.com/apple/swift/blob/c1211a3f78992c89a3ab4d638c378c6f45ab8fe8/stdlib/public/core/AutoDiff.swift#L364
[`differentiableFunction(from:)`]: https://github.com/apple/swift/blob/c1211a3f78992c89a3ab4d638c378c6f45ab8fe8/stdlib/public/core/AutoDiff.swift#L103
[`differentiableFunction(from:)` (arity 2)]: https://github.com/apple/swift/blob/c1211a3f78992c89a3ab4d638c378c6f45ab8fe8/stdlib/public/core/AutoDiff.swift#L120

[automatic differentiation]: https://en.wikipedia.org/wiki/Automatic_differentiation

[Richard Wei]: http://github.com/rxwei
[Dan Zheng]: http://github.com/dan-zheng
[Marc Rasi]: http://github.com/marcrasi
[Parker Schuh]: http://github.com/pschuh
