# Swift for TensorFlow Design Overview

* Date: April 2018

Swift for TensorFlow provides a new programming model for TensorFlow - one that combines the performance of graphs with the flexibility and expressivity of Eager execution, while keeping a strong focus on improved usability at every level of the stack.  In order to achieve our goals, we scope in the possibility of making (carefully considered) compiler and language enhancements, which enables us to provide a great user experience.

For users, we’ve designed Swift for TensorFlow to feel like a simple and obvious tool for writing machine learning libraries and models that "just work".  However, if you look under the hood, the implementation of this user experience is a bunch of mostly independent features and subsystems that compose and feel natural together, but which can also be used in isolation.

This document provides a high level view of these subcomponents and describe how they interact and fit together.  The goal of this document is to describe the big picture without requiring extensive subject matter expertise.  Technical deep-dive white papers are linked to provide a deeper perspective where it makes sense, as are links to the code itself.

We go describe these pieces of the project:

 - [Swift](#swift)
 - [TensorFlow](#tensorflow)
 - [Graph Program Extraction](#graph-program-extraction)
 - [The TensorFlow module](#the-tensorflow-module)
 - [Automatic Differentiation](#automatic-differentiation)
 - [Python Interoperability](#python-interoperability)
 - [Future Directions](#future-directions)

## Swift
Swift is an [open source](https://swift.org/) general-purpose programming language, which has a large and growing user base.  We chose Swift because it has an [open language design process](https://github.com/apple/swift-evolution) and for specific technical reasons detailed in the "[Why *Swift* for TensorFlow](WhySwiftForTensorFlow.md)" document.  We assume that most readers are unfamiliar with it, so we’ll briefly touch on some additional important things about it here.

The development of Swift started in 2010, and aimed to bring the best practices in programming language design together into one system rather than trying for academic novelty or to religiously propagate programming methodologies.  As a result, it supports multi-paradigm development (e.g. functional, OOP, generic, procedural, etc) all in one system,  and brings many well-known concepts from academic languages (e.g. [pattern matching](http://alisoftware.github.io/swift/pattern-matching/2016/03/27/pattern-matching-1/), [algebraic data types](https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/Enumerations.html), and type classes) into the forefront.  Instead of strongly encouraging developers to rewrite all their code in Swift, it pragmatically focuses on interoperability with other languages, e.g., allowing you to directly import C header files and use them without an [FFI](https://en.wikipedia.org/wiki/Foreign_function_interface) and (now) the ability to use Python APIs without wrappers.

Swift has the audacious goal of spanning all the way from low-level systems programming to high-level scripting, with a focus on being [easy to learn and use](https://www.apple.com/swift/playgrounds/).  Because Swift needs to be easy to learn and use but also powerful, it relies on the principle of [progressive disclosure of complexity](https://www.nngroup.com/articles/progressive-disclosure/), which aggressively factors the cost of complexity onto the people who benefit from that complexity.  The "scripting language feel" combined with high performance is very useful for machine learning.

A final pertinent aspect of the design of Swift is that much of the Swift language is actually implemented in its standard library.  "Builtin" types like [Int](https://developer.apple.com/documentation/swift/int) and [Bool](https://developer.apple.com/documentation/swift/bool) are actually just structs defined in the standard library that wrap magic types and operations.  As such, sometimes we joke that Swift is just "syntactic sugar for LLVM".   This capability is very important to our work because the Tensor type in the [TensorFlow module](#the-tensorflow-module) is just "syntactic sugar" for TensorFlow, and the `PythonObject` type is just syntactic sugar for `PyObject*`!

There is a lot more that is cool about Swift and a ton of content available online.  If you are interested in learning more about general Swift programming concepts, here are a few links to get started:

 - [A Swift Tour](https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/GuidedTour.html) is a skimmable tour of the high level syntax and feel of Swift, and is part of the larger "The Swift Programming Language" book.
 - Value semantics are powerful and play an important role in Swift code, as explained in "[Building Better Apps with Value Types in Swift](https://developer.apple.com/videos/play/wwdc2015/414/)" [[YouTube](https://www.youtube.com/watch?v=av4i3x-aZbM)].
 - Swift supports classic OOP, but has adapted ideas from the Haskell type system.  This is explained in "[Protocol-Oriented Programming in Swift](https://developer.apple.com/videos/play/wwdc2015/408/)" [[YouTube](https://www.youtube.com/watch?v=g2LwFZatfTI)].

One warning: Swift evolved rapidly in its early years, so you should be careful with anything before Swift 3 (released in 2016).

## TensorFlow

[TensorFlow](https://tensorflow.org/) is a popular and widely-used machine learning framework.  TensorFlow provides a graph-based Python API where you explicitly build graph operations and then execute the graph one or more times with the session API.  In addition, TensorFlow added [eager execution](https://www.tensorflow.org/programmers_guide/eager) which lets you call operations one-by-one in a Pythonic mode, but without the benefits of graphs.

In that context, many users will initially think Swift for TensorFlow is just a straight language binding.  However, Swift for TensorFlow lets you write imperative eager execution-style code,  while Swift gives you the full performance of the explicit graph APIs.  The magic behind this is a [compiler transformation](#graph-program-extraction) that analyzes your code and automatically builds the TensorFlow graph and runtime calls for you.  The nice thing about this is that TensorFlow "just works", and you don’t have to think about graphs at all.

To understand how this works, it is important to know how TensorFlow represents its graphs.  [TF_Function](https://github.com/tensorflow/tensorflow/blob/master/tensorflow/c/c_api.h) represents a tensor computation as a function that takes some number of tensor inputs and produces some number of tensor results.  Each "op"/"node" in a TensorFlow graph is defined by a string op name, a list of input values, a list of attributes (which are guaranteed to be constants), and produces some number of tensor results.  Each input and result value has a "dtype" associated with it that describes the element type (specified by the `TF_DataType` enum), and attributes also have their own simple type system (integer, string, float, shape, etc).  The details of this are [described in the TensorFlow documentation](https://www.tensorflow.org/extend/adding_an_op).

Swift for TensorFlow has a low-level syntax that gives you direct access to any op, using a distinct `#tfop` syntax (this syntax is a placeholder that is likely to be revised).
For example, here are a few methods defined on the Tensor type (simplified slightly for presentation),
you can see their full definition in [Ops.swift](https://github.com/apple/swift/blob/tensorflow/stdlib/public/TensorFlow/Ops.swift).

```swift
struct Tensor<Scalar> {
  ...
  // Implement the infix `+` operator on Tensor in terms of the TensorFlow `Add` op,
  // which takes two input tensors and returns one result.
  static func +(lhs: Tensor, rhs: Tensor) -> Tensor {
    return #tfop("Add", lhs, rhs)
  }
  // Another example that implements a method in terms of the TensorFlow `Conv2D` op,
  // which takes two input tensors, as well as a `strides` and `padding` attribute.
  func convolved2D(withFilter filter: Tensor,
                   strides: (Int32, Int32, Int32, Int32),
                   padding: Padding) -> Tensor {
    return #tfop("Conv2D", handle, filter,
                 strides: [strides.0, strides.1, strides.2, strides.3],
                 padding: padding.cName)
  }
}
```

While the `+` example is very simple, the convolution example shows another important role that these functions play: they are adaptors that handle bridging between the "Swift way of thinking about things" and the "TensorFlow way of thinking about things".  For example, Swift programmers get to think about paddings as a Swift enum, even though TensorFlow takes strings.  Similarly, strides can be passed as a strongly-typed 4-ary tuple and this code handles erasing that type information when passing it to TensorFlow as an array.

## Graph Program Extraction

The Graph Program Extraction transformation is the key technique that allows TensorFlow integration to work in a seamless way.  This acts like an additional stage in the compiler, which uses static analysis to find tensor operations and split them out to a TensorFlow graph.  At a high level, the enhanced Swift compiler looks like this:

<p align="center">
  <img src="images/DesignOverview-Pipeline.png?raw=true" alt="Compiler Pipeline"/>
</p>

First, the compiler finds the tensor operations in the code (which is trivial
due to the low-level `#tfop` syntax described above).  Next, it desugars
high-level abstractions (like structs, tuples, generics, functions, variables,
etc) that connect tensor operations through a process called "deabstraction".
After deabstraction, the tensor operations are directly connected to each other
through [SSA](https://en.wikipedia.org/wiki/Static_single_assignment_form)
dataflow edges and are embedded in a control flow graph represented in the
[Swift Intermediate Language](https://github.com/apple/swift/blob/master/docs/SIL.rst) (SIL).
The code for this is primarily implemented in [TFDeabstraction.cpp](https://github.com/apple/swift/blob/tensorflow/lib/SILOptimizer/Mandatory/TFDeabstraction.cpp).

Once the tensor operations are desugared, a transformation we call "partitioning" extracts the graph operations from the program and builds a new SIL function to represent the tensor code.  In addition to removing the tensor operations from the host code, new calls are injected that call into [our new runtime library](#runtime-entry-points-for-extraction) to start up TensorFlow, rendezvous to collect any results, and send/receive values between the host and the tensor program as it runs.  The bulk of the Graph Program Extraction transformation itself lives in [TFPartition.cpp](https://github.com/apple/swift/blob/tensorflow/lib/SILOptimizer/Mandatory/TFPartition.cpp).

Once the tensor function is formed, it has some transformations applied to it, and is eventually emitted to a TensorFlow graph using the code in [TFLowerGraph.cpp](https://github.com/apple/swift/blob/tensorflow/lib/SILOptimizer/Mandatory/TFLowerGraph.cpp). After the TensorFlow graph is formed, we serialize it to a protobuf and encode the bits directly into the executable, making it easy to load at program runtime.

We aren’t aware of any other system using this approach, but our implementation draws on a lot of related conceptual work, including [program slicing](https://en.wikipedia.org/wiki/Program_slicing), [abstract interpretation](https://en.wikipedia.org/wiki/Abstract_interpretation), and is implemented as a [static compiler analysis](https://en.wikipedia.org/wiki/Static_program_analysis).  Please see our detailed [Graph Program Extraction whitepaper](GraphProgramExtraction.md) for more information on how all of this works.

Finally, while TensorFlow is the reason we built this infrastructure, its algorithms are independent of TensorFlow itself: the same compiler transformation can extract any computation that executes asynchronously from the host program while communicating through sends and receives.  This is useful and can be applied to anything that represents computation as a graph, including other ML frameworks, other kinds of accelerators (for cryptography, graphics, transcoding, etc), and general distributed systems programming models based on graph abstractions.  We are interested in exploring new applications of this algorithm in the future.

## The TensorFlow module

The TensorFlow module is the library of code you get as a result of `import TensorFlow` in a Swift program.  It is written in Swift and lives in the [stdlib/public/TensorFlow](https://github.com/apple/swift/tree/tensorflow/stdlib/public/TensorFlow) directory.  It implements a few different things:

### User APIs: Tensor, ShapedArray, etc.

As we described in the [section about Swift](#swift), a lot of the Swift experience is actually defined in the standard library, not the compiler itself.  Similarly, because our Graph Program Extraction approach is so general and flexible, the TensorFlow module defines most of the user experience and feel of working with TensorFlow.  Design choices about the user experience are not baked into the language or compiler, giving us a lot of latitude to experiment with different approaches in the TensorFlow library.

Our most significant design constraint is that we don’t want users of Swift for TensorFlow to write code that accidentally causes unnecessary copies back and forth between the host and the accelerator.  Because of this, we chose to implement a user model that provides two primary concepts: "arrays" and "tensors".  Both of these represent n-dimensional tensors of values, but the "arrays" in our system should be thought of as data in the host program, whereas "tensors" are values that are primarily managed by TensorFlow.  Among other things, this means that "arrays" conform to [MutableCollection](https://developer.apple.com/documentation/swift/mutablecollection) and [RangeReplaceableCollection](https://developer.apple.com/documentation/swift/rangereplaceablecollection) and thus have normal collection APIs, but `Tensor` has methods and operators that correspond to TensorFlow ops.

Both "arrays" and "tensors" have dynamically ranked n-dimensional versions, named
[`ShapedArray`](https://www.tensorflow.org/api_docs/swift/Structs/ShapedArray) and
[`Tensor`](https://www.tensorflow.org/api_docs/swift/Structs/Tensor) respectively.
We are also experimenting with statically ranked versions
([`Array2D`](https://www.tensorflow.org/api_docs/swift/Structs/Array2D),
[`Array3D`](https://www.tensorflow.org/api_docs/swift/Structs/Array3D), etc. which compose on top of
[`Swift.Array`](https://developer.apple.com/documentation/swift/array)) and
([`Tensor1D`](https://www.tensorflow.org/api_docs/swift/Structs/Tensor1D),
[`Tensor2D`](https://www.tensorflow.org/api_docs/swift/Structs/Tensor2D),
[`Tensor3D`](https://www.tensorflow.org/api_docs/swift/Structs/Tensor3D), etc).
Here are a couple of simple examples showing `Tensor` and `ShapedArray`:

```swift
// `Tensor` examples.
var matrix: Tensor<Float> = [[1, 2], [3, 4]]
// `matrix` represents [[1, 2], [3, 4]].

// Arithmetic operations, using TensorFlow.
let sum = matrix + matrix
let root = sqrt(matrix)
let matrixProduct = matrix • matrix
// `sum` represents [[2.0, 4.0], [6.0, 8.0]].
// `root` represents [[1.0, 1.41421], [1.73205, 2.0]].
// `matrixProduct` represents [[7.0, 10.0], [15.0, 22.0]].

// Convert `Tensor` to `ShapedArray`.
let array2D = ShapedArray(matrix)
// `array2D` is stored on the host.
```

```swift
// `ShapedArray` examples.
var matrix = ShapedArray(shape: [3, 2], scalars: [1, 2, 0, 0, 5, 6])
// `matrix` represents [[1, 2], [0, 0], [5, 6]].

let element = matrix[0]
// `element` is a `ShapedArraySlice` with shape [2], representing [1, 2].

matrix[1] = ShapedArraySlice(shape: [2], scalars: [3, 4])
// The second element in `matrix` has been mutated.
// `matrix` now represents [[1, 2], [3, 4], [5, 6]].

let zeros = ShapedArray(repeating: 0, shape: [3, 2])
let subarray = matrix.prefix(2)
// `subarray` is a `ShapedArraySlice` with shape [2, 2], representing [[1, 2], [3, 4]].
matrix[0..<2] = zeros.prefix(2)
// The first 2 elements in `matrix` have been modified.
// `matrix` now represents [[0, 0], [0, 0], [5, 6]].

// Convert `ShapedArray` to `Tensor`.
let tensor2D = Tensor(matrix)
// It's now possible to perform TensorFlow operations on `tensor2D`.
```

The implementation of `Tensor` builds on the `#tfop` magic syntax that builds TensorFlow graph nodes, and is defined in
[Tensor.swift](https://github.com/apple/swift/blob/tensorflow/stdlib/public/TensorFlow/Tensor.swift),
[Ops.swift](https://github.com/apple/swift/blob/tensorflow/stdlib/public/TensorFlow/Ops.swift),
[RankedTensor.swift.gyb](https://github.com/apple/swift/blob/tensorflow/stdlib/public/TensorFlow/RankedTensor.swift.gyb),
and [TensorProtocol.swift](https://github.com/apple/swift/blob/tensorflow/stdlib/public/TensorFlow/TensorProtocol.swift).
The implementation of `ShapedArray` follows standard techniques used when implementing Swift collections and is defined primarily in
[ShapedArray.swift](https://github.com/apple/swift/blob/tensorflow/stdlib/public/TensorFlow/ShapedArray.swift) and
[RankedArray.swift.gyb](https://github.com/apple/swift/blob/tensorflow/stdlib/public/TensorFlow/RankedArray.swift.gyb).
In addition to the `Tensor` family of types, we are experimenting with building abstractions on top of the TensorFlow graph nodes for data pipelines, resources, variants, and other things representable as graph nodes.

### Runtime Entry Points for Extraction

The [Graph Program Extraction algorithm](#graph-program-extraction) splits the tensor operations out to a TensorFlow graph which is serialized to a protobuf and encoded into the program’s executable.  It rewrites the host code to insert calls to "start tensor program", "finish tensor program", and "terminate tensor program" runtime entry points, which are implemented in the [CompilerRuntime.swift](https://github.com/apple/swift/blob/tensorflow/stdlib/public/TensorFlow/CompilerRuntime.swift) file in terms of TensorFlow APIs.

Our runtime currently has several supported paths for driving TensorFlow, including paths that enable XLA, paths that go through classic executor, paths that uses the "eager execution" runtime entry points, and some specialized support for Cloud TPU configurations.  This is still rapidly evolving and subject to continuous change.

The most significant unimplemented piece of our compiler and runtime model is support for sending and receiving data between co-executing asynchronous host and TensorFlow programs.  This is an incredibly important part of our model that allows you to transparently use host calls (e.g. `print` or Xcode Playground value logging) on Tensor values, and intermix host and accelerator code freely.  This is a top priority to implement in the coming weeks.  In the meantime, we have full support for arguments and results that are passed and received at the start and end of the tensor program.

## Automatic Differentiation

[Automatic differentiation](https://en.wikipedia.org/wiki/Automatic_differentiation) (AD) is a powerful technique that all machine learning frameworks are expected to implement, because gradients are so important for this work (e.g. with [SGD](https://en.wikipedia.org/wiki/Stochastic_gradient_descent)).  TensorFlow implements automatic differentiation as a TensorFlow graph transformation, but we would like to deploy more powerful techniques to improve user experience in failure cases, enable differentiating custom data structures, recursion, and higher-order differentiation.  As such, we built a stand-alone AD feature for Swift: one that is completely independent of the standard TensorFlow implementation of AD, and also completely independent of TensorFlow support in Swift.

The way this works is by having Swift AD support arbitrary user-defined types.  Swift for TensorFlow builds on this by making its Tensor types conform to the AD system, allowing them to participate as you’d expect.  A nice thing about this is that Swift programmers interested in non-Tensor numerical analysis can use AD for any other types that are important for their work.

<p align="center">
  <img src="images/DesignOverview-AD.png?raw=true" alt="AutoDiff flow"/>
</p>

Automatic differentiation in Swift is a compiler IR transformation implemented with static analysis. When differentiating a function in reverse mode, the compiler produces a separate functions that contain the corresponding "primal code" and "adjoint code", which in turn compute the partial derivatives of the model output with respect to the input parameters. Since we want AD in Swift to be completely general across all use cases and allow custom data structures and arbitrary functions, the compiler makes no assumption about individual math operations.  Instead, the developer specifies the adjoint code to use for a function, and how two back-propagated adjoint values should combine - all in pure Swift code. The compiler will then differentiate and chain any uses of these functions.

We use the `@differentiable` attribute on a function to specify the custom adjoint for the function. The first parameter to `@differentiable` specifies whether the function is differentiable using forward-mode (not supported yet) or reverse-mode AD. The second argument specifies an adjoint function that takes the original arguments, intermediate primal values, the original result and a seed (back-propagated adjoint value from another function) and computes the gradient.

```swift
@differentiable(reverse, adjoint: adjointLog)
func log(_ x: Float) -> Float {
  ...
}

func adjointLog(_ x: Float, originalResult: Float, seed: Float) -> Float {
  return seed / x
}
```

In addition to making the operator differentiable, the compiler needs to know how to combine two derivatives for "fanouts" in the forward pass (usually a `+` by the sum and product rule, but sometimes also broadcasting) and how to create a zero gradient.  Types can specify custom behavior by implementing a conformance to the `VectorNumeric` protocol, and we’ve made all `FloatingPoint` types conform. `Tensor` also conforms when its scalar type is `FloatingPoint`. With this foundation, the user can request the gradient of any function over `VectorNumeric` types so long as the functions called along the data flow are differentiable. When any operation along the data flow is not differentiable, e.g. a call to a non-differentiable function or an assignment to a global variable, the compiler will produce a compile-time error and point to the location of the relevant problem.

We provide two differential operators for requesting the gradient of a function: `#gradient()` and `#valueAndGradient()`. The former takes a function and returns another function that computes the gradient of the original function. The latter takes a function and returns another function that computes both the result and the gradient of the original function. An optional variadic argument `wrt:` specifies the indices of parameters (of `self`) to differentiate with respect to. The following example demonstrates how to request the gradient of a differentiable function with respect to certain arguments.

```swift
func cube<T : FloatingPoint>(_ x: T, _ str: String) -> T {
  print(str)
  return x * x * x
}

let dCube_dx = #gradient(cube, wrt: .0)

cube(5, "hi")  // prints "hi" and returns 125
dCube_dx(5, "hi") // prints "hi" and returns 75
```

Today, we have the basic infrastructure in place to support reverse-mode AD on straight-line code with well-defined adjoints, but we plan to support full-fledged control flow and discuss the need for forward-mode AD with the community.  To learn more about automatic differentiation, see [Automatic Differentiation in Swift](AutomaticDifferentiation.md).

## Python Interoperability

A large part of the machine learning community uses Python, and we all want to heavily leverage the massive data science, visualization, and other random packages that Python provides to get our jobs done.  There are a few things that we can do to reduce the burden of moving from programming in Python to programming in Swift for TensorFlow.  For example, Swift already supports a command line interpreter, and `#!` script workflows.  We believe that great Jupyter Notebook integration is important because it is a part of many people’s workflows.

To further smooth the transition, we made it possible to directly call Python APIs from Swift, which allows ML programmers to continue using data science and other useful APIs while also getting the benefits of Swift for their TensorFlow code.  Here is an example of what this looks like in practice, with commented out code that shows the pure-Python syntax for comparison:

```swift
// NumPy example:
let np = Python.import("numpy")             // import numpy as np
let a = np.arange(15).reshape(3, 5)         // a = np.arange(15).reshape(3, 5)
let b = np.array([6, 7, 8])                 // b = np.array([6, 7, 8])

// Pickle example:
let gzip = Python.import("gzip")            // import gzip as gzip
let pickle = Python.import("pickle")        // import pickle as pickle
let file = gzip.open("mnist.pkl.gz", "rb")  // file = gzip.open("mnist.pkl.gz", "rb")
                                            // (images, labels) = pickle.load(file)
let (images, labels) = pickle.load(file).tuple2
print(images.shape) // (50000, 784)            print(images.shape)
```

As you can see, the syntax here is very close: the major differences are that Swift requires values to be declared before use, and that we decided to put [Python builtin functions](https://docs.python.org/3/library/functions.html) like `import`, `type`, `slice`, etc under a `Python.` namespace (to avoid cluttering the global scope).  This doesn’t require SWIG or any other wrappers, so it is super easy to use.

This feature is accomplished without making Python specific changes to the compiler or language - it is completely implemented in the [Python.swift file](https://github.com/apple/swift/blob/tensorflow/stdlib/public/Python/Python.swift).  This means that we can use the same techniques to directly integrate with other dynamic language runtimes (e.g. Javascript, Ruby, etc) if it becomes important in the future.  Python support is also completely independent of the other TensorFlow and automatic differentiation logic we’re building in the rest of the project.  It is a generally useful extension to the Swift ecosystem that can stand alone, useful for server side development or anything else that wants to interoperate with existing Python APIs.

To find out more about how this works, please check out the [Python Interoperability Deep Dive](PythonInteroperability.md), or browse the implementation in [Python.swift on GitHub](https://github.com/apple/swift/blob/tensorflow/stdlib/public/Python/Python.swift).

## Future Directions

We’re focusing on finishing the basic Swift for TensorFlow model, gaining more experience using it, and start building a developer community.  Despite that, we have tons of ideas for how to push things forward - and welcome additional ideas of course!  For example:

**Availability Checking:** Swift has a powerful model for working with conditionally available functionality known as "[availability checking](https://www.raywenderlich.com/139077/availability-attributes-swift)", and the TensorFlow ecosystem has many similar challenges: Many ops are only available on certain devices, some ops only work with certain dtypes, and some deployment targets like XLA and TFLite have additional restrictions.  We’d like to consider extending availability checking or building a similar system to allow us to statically diagnose misuse of Tensor ops for the hardware and configuration you’re deploying for.  We should be able to directly point to the problematic line of code and give a detailed error message about problems we detect.

**Deployment Support:** We’d like to explore a model where deployed models are explicitly declared in code, including the device(s) they are intended to support.  This enables improved availability checking (described above), allows better management of the interfaces used for inference, eliminates certain classes of bugs, and should directly support deployment workflows that want to update weight values without recompiling and changing code.  We have an initial plan of how to pursue this but need to develop the ideas out more.

**Shape Checking:** Shape errors are an ongoing problem for machine learning research and productivity.  We already have some basic shape checks from the TensorFlow graph building APIs, but we need to invest in first class support for this to produce better diagnostics and diagnose more errors at high level API boundaries instead of inside the implementation of those APIs.  We have initial ideas of how this could work, but need to explore this much further.

**Named Dimensions:** A frequently requested feature is to be able to use symbolic dimension names in Tensors.  There are several different possible models that could be explored here.

**Differentiating Opaque Closures:** Statically differentiating a function requires the body of the function to be visible to the compiler. However, this limits the expressiveness of the differential operator, e.g. users can’t apply the gradient operator to a function argument that has a function type because the compiler can’t always see into the body of the original function. We will discuss the possibility to introduce a new function convention - when a differentiable function is passed around, a pointer to its primal and adjoint gets passed along. This enables the compiler to directly call the primal and the adjoint, without the need to see into the function declaration.  This is important for class and protocol methods.

**Quantization Support:** We believe we can get a much better user experience for [fixed-point quantization tools](https://www.tensorflow.org/performance/quantization) if we integrate them into the compiler, and this should help with integrating quantization into the training process.
