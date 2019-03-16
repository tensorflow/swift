# Dynamic property iteration using key paths

[Richard Wei](https://github.com/rxwei), [Dan Zheng](https://github.com/dan-zheng)

Last updated: March 2019

## Background and motivation

The ability to iterate over the properties of a type is a powerful reflection
technique. It enables algorithms that can abstract over types with arbitrary
properties: examples include property-based default implementations of
equality/comparison/hash functions.

Many dynamic languages offer custom property iteration as an accessible
top-level feature (e.g. [`dir`][Python_dir] in Python and
[`Object.values`][JS_Object_values] in JavaScript).

Static types can complicate custom property iteration: since a type’s properties
may have different types, representing a unified property type may require type
erasure. Statically-typed languages typically achieve custom property iteration
via metaprogramming or runtime reflection.

Here’s a non-comprehensive list of different approaches to custom property
iteration:

- Dynamic languages
  - Python: the [`dir` builtin][Python_dir] returns a list of valid attributes
    for an object.
  - JavaScript: [`Object.keys`][JS_Object_keys]
    and [`Object.values`][JS_Object_values] return an array of property
    names/values for an object.
  - Objective-C: [key-value coding (KVC)][ObjC_KVC] defines string-based APIs
    for getting/setting properties.
- Runtime reflection
  - Java: [`Class.getFields`][Java_getFields] returns an array reflecting the
    public fields of a class.
  - Swift: [`Mirror`][Swift_Mirror], a "representation of the substructure and
    display style of an instance of any type."
- Metaprogramming/macros
  - [C][C_macro], [Rust][Rust_macro], etc.
- Other
  - [Lenses in functional programming][Lenses].

A motivating use case for custom property iteration is machine learning
optimization. Machine learning optimizers update structs of parameters using
some algorithm (e.g. stochastic gradient descent).

Parameters are represented as struct stored properties and may have different
types: they may be floating-point numbers (e.g. `Float` or `Double`), or
aggregates like collections (e.g. `[Float]`) or other nested structs of
parameters.

How can we define generic optimizers that work with arbitrary parameters?

It is not possible to represent a "heterogenous collection of parameters"
without losing flexibility or type information. Instead, stored property
iteration is necessary:

```swift
func update(layer: inout Parameters, gradients: Parameters) {
    // Pseudocode `for..in` syntax for iterating over stored properties.
    // Detailed design below.
    for (inout θ, dθ) in zip(parameters, gradients) {
        θ -= learningRate * dθ
    }
}
```

## Design

In Swift, custom property iteration is implemented using key paths and the
[`KeyPathIterable`](https://www.tensorflow.org/swift/api_docs/Protocols/KeyPathIterable)
protocol.

Key paths are a statically-typed mechanism for referring to the properties
(and other members) of a type. The `KeyPathIterable` protocol represents types
whose values provide custom key paths to properties or elements. It has two
requirements, similar to
[`CaseIterable`](https://developer.apple.com/documentation/swift/caseiterable):

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

The compiler can automatically provide an implementation of the
`KeyPathIterable` requirements for any struct type, based on its stored
properties: `AllKeyPaths` is implemented as `[PartialKeyPath<Self>]` and
`allKeyPaths` returns a collection of key paths to all stored properties.

`KeyPathIterable` defines some default methods for accessing nested key paths
and filtering key paths based on value type and mutability. These default
methods are all computed based on `allKeyPaths`.

|                       | Key paths to top-level members                  | Key paths to recursively all nested members                |
|:---------------------:|-------------------------------------------------|------------------------------------------------------------|
| Non-writable, untyped <br><code>[PartialKeyPath<Self>]</code> | <code>allKeyPaths</code>                        | <code>recursivelyAllKeyPaths</code>                        |
| Non-writable, typed <br><code>[KeyPath<Self, T>]</code> | <code>allKeyPaths<T>(to: T.Type)</code>         | <code>recursivelyAllKeyPaths<T>(to: T.Type)</code>         |
| Writable, typed <br><code>[WritableKeyPath<Self, T>] | <code>allWritableKeyPaths<T>(to: T.Type)</code> | <code>recursivelyAllWritableKeyPaths<T>(to: T.Type)</code> |

Additionally, conformances to `KeyPathIterable` for `Array` and `Dictionary` are
provided in the standard library: `Array.allKeyPaths` returns key paths to all
elements and `Dictionary.allKeyPaths` returns key paths to all values. These
enables `recursivelyAllKeyPaths` to recurse through the elements/values of these
collections.

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

## Basic example

Here is a contrived example demonstrating basic `KeyPathIterable` functionality.

```swift
struct Point: KeyPathIterable {
    var x, y: Float
}
struct Foo: KeyPathIterable {
    let int: Int
    let float: Float
    var points: [Point]
}

var foo = Foo(int: 0, float: 0, points: [Point2D(x: 1, y: 2)])
print(foo.allKeyPaths)
// [\Foo.int, \Foo.float, \Foo.points]
print(foo.allKeyPaths(to: Float.self))
// [\Foo.float]
print(foo.recursivelyAllKeyPaths(to: Float.self))
// [\Foo.float, \Foo.points[0].x, \Foo.points[0].y]
print(foo.recursivelyAllWritableKeyPaths(to: Float.self))
// [\Foo.points[0].x, \Foo.points[0].y]

for kp in foo.recursivelyAllWritableKeyPaths(to: Float.self) {
    foo[keyPath: kp] += 1
}
print(foo)
// Foo(int: 0, float: 0, points: [Point2D(x: 2, y: 3)])
```

## Applications

`KeyPathIterable` can be used to define a default `Hashable` implementation
without using derived conformances. This is adapted from
[a tweet by Joe Groff](https://twitter.com/jckarter/status/868195828955062272):

```swift
// These implementations will be used for types that conform to
// both `KeyPathIterable` and `Hashable`.
extension Hashable where Self: KeyPathIterable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.allKeyPaths.elementsEqual(rhs.allKeyPaths) else {
            return false
        }
        for kp in lhs.allKeyPaths {
            guard let lhsValue = lhs[keyPath: kp] as? AnyHashable,
                  let rhsValue = rhs[keyPath: kp] as? AnyHashable,
                  lhsValue == rhsValue
            else {
                return false
            }
        }
        return true
    }

    func hash(into hasher: inout Hasher) {
        for kp in allKeyPaths {
            guard let value = self[keyPath: kp] as? AnyHashable else {
                continue
            }
            value.hash(into: &hasher)
        }
    }
}

struct Person: KeyPathIterable, Hashable {
    var firstName: String
    var age: Int
    var friends: [Person]
}
let johnSmith = Person(firstName: "John", age: 30, friends: [])
let johnDoe = Person(firstName: "John", age: 30, friends: [])
let jane = Person(firstName: "Jane", age: 27, friends: [johnSmith])

print(johnSmith == johnDoe) // true
print(johnSmith.hashValue == johnDoe.hashValue) // true

print(johnSmith == jane) // false
print(johnSmith.hashValue == jane.hashValue) // false
```

`KeyPathIterable` can also be used to implement machine learning optimizers.
Optimizers update structs of parameters by iterating over recursively all
writable key paths to parameters.

```swift
class SGD<Parameter: BinaryFloatingPoint> {
    let learningRate: Parameter

    init(learningRate: Parameter = 0.01) {
        precondition(learningRate >= 0, "Learning rate must be non-negative")
        self.learningRate = learningRate
    }

    func update<Parameters: KeyPathIterable>(
        _ parameters: inout Parameters,
        with gradient: Parameters
    ) {
        // Iterate over recursively all writable key paths to the
        // parameter type.
        for kp in parameters.recursivelyAllWritableKeyPaths(to: Parameter.self) {
            parameters[keyPath: kp] -= learningRate * gradient[keyPath: kp]
        }
    }
}

struct DenseLayer: KeyPathIterable {
    // Parameters.
    var weight, bias: Float
    // Non-parameter.
    var activation: (Float) -> Float = { $0 }

    init(weight: Float, bias: Float) {
        self.weight = weight
        self.bias = bias
    }
}

struct MyMLModel: KeyPathIterable {
    // Parameters.
    var layers: [DenseLayer]
    // Non-parameters.
    var isTraining: Bool = false

    init(layers: [DenseLayer]) {
        self.layers = layers
    }
}

let dense = DenseLayer(weight: 1, bias: 1)
var model = MyMLModel(layers: [dense, dense])
let gradient = model
let optimizer = SGD<Float>()
optimizer.update(&model, with: gradient)

dump(model)
// ▿ MyMLModel
//   ▿ layers: 2 elements
//     ▿ DenseLayer
//       - weight: 0.99
//       - bias: 0.99
//       - activation: (Function)
//     ▿ DenseLayer
//       - weight: 0.99
//       - bias: 0.99
//       - activation: (Function)
//   - isTraining: false
```

## Extended design

We explored an [extended modular design](https://forums.swift.org/t/storedpropertyiterable/19218)
for custom property iteration that uses two protocols: `StoredPropertyIterable`
and `CustomKeyPathIterable`.

- `StoredPropertyIterable` models the static layout of structs. It provides a
  static computed property `allStoredProperties` that represents a collection of
  key paths to all stored properties in the type.

- `CustomKeyPathIterable` models both static and dynamic structures. It provides
  an instance computed property `allKeyPaths` that can represent stored
  properties, or dynamic properties like elements.

## Acknowledgements

The authors would like to thank Dominik Grewe and Dimitrios Vytiniotis for their
key-path-related ideas, which contributed to the design of the `KeyPathIterable`
protocol.

[Python_dir]: https://docs.python.org/3/library/functions.html#dir
[JS_Object_keys]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_objects/Object/keys
[JS_Object_values]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_objects/Object/values
[ObjC_KVC]: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueCoding/index.html
[Java_getFields]: https://www.tutorialspoint.com/java/lang/class_getfields.htm
[Swift_Mirror]: https://developer.apple.com/documentation/swift/mirror
[Lenses]: https://en.wikibooks.org/wiki/Haskell/Lenses_and_functional_references
[C_macro]: https://natecraun.net/articles/struct-iteration-through-abuse-of-the-c-preprocessor.html
[Rust_macro]: https://stackoverflow.com/questions/38111486/how-do-i-iterate-over-elements-of-a-struct-in-rust

[KeyPathIterable]: https://tensorflow.org/swift/api_docs/Protocols/KeyPathIterable
