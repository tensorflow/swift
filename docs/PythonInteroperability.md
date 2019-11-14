# Python Interoperability

* Date: April 2018

As described in the [design overview document](DesignOverview.md), Python API interoperability is an important requirement for this project.  While Swift is designed to integrate with other programming languages (and their runtimes), the nature of dynamic languages does not require the deep integration needed to support static languages.  Python in particular is [designed to be embedded](https://docs.python.org/3/extending/index.html) into other applications and has a [simple C interface API](https://oleb.net/blog/2017/12/importing-c-library-into-swift/).  For the purposes of our work, we can provide a meta-embedding, which allows Swift programs to use Python APIs as though they are directly embedding Python itself.

To accomplish this, the Swift script/program simply links the Python interpreter into its code.  Our goal changes from "how do we work with Python APIs" into a question of "how do we make Python APIs feel natural, accessible, and easy to reach for from Swift code?"  This isn’t a trivial problem - there are significant design differences between Swift and Python, including their approaches to error handling, the super-dynamic nature of Python, the differences in surface-level syntax between the two languages, and the desire to not "compromise" the things that Swift programmers have come to expect.  We also care about convenience and ergonomics and think it is unacceptable to require a wrapper generator like SWIG.

The TL;DR on this whitepaper is we feel good about this direction and think that there are interesting aspects of this work: it is great that we are able to achieve good Python interoperability with a library written in Swift by composing Python-independent language features.  This allows other communities to compose the same feature set to directly integrate with other dynamic languages which are important to other communities (e.g. Javascript, Ruby, etc).  It is also great that this work is independent of the automatic differentiation and [Graph Program Extraction](GraphProgramExtraction.md) features of Swift for TensorFlow.

## Overall approach

Our overall approach is based on the observation that Python is strongly typed but - like most dynamically typed languages - its type system is enforced at runtime.  While there have been many attempts to retrofit a [static type system](https://en.wikipedia.org/wiki/Type_system#Static_type_checking) on top of it (e.g. [mypy](http://mypy-lang.org/), [pytype](https://github.com/google/pytype) and [others](https://www.jetbrains.com/pycharm/)), they rely on unsound type systems so they aren’t a full solution we can rely on, and furthermore they cut against many of the design premises that make Python and its libraries truly great.

Many people see Swift as a statically typed language and therefore jump to the conclusion that the right solution is to shoehorn Python’s fluid form into a statically defined hole.  However, others realize that Swift combines the benefits of a powerful static type system with an (often under-appreciated!) dynamic type system.  Instead of attempting to force Python’s dynamic type system to be something it is not, we choose to meet Python where it is and fully embrace its dynamically typed approach.

The end result of this is that we can achieve a very natural Python experience - directly in Swift code.  Here is an example of what this looks like; the commented-out code shows the pure-Python syntax for comparison:

```swift
// Python:
//    import numpy as np
//    a = np.arange(15).reshape(3, 5)
//    b = np.array([6, 7, 8])
let np = Python.import("numpy")
let a = np.arange(15).reshape(3, 5)
let b = np.array([6, 7, 8])

// Python:
//    import gzip as gzip
//    import pickle as pickle
let gzip = Python.import("gzip")
let pickle = Python.import("pickle")

// Python:
//    file = gzip.open("mnist.pkl.gz", "rb")
//    (images, labels) = pickle.load(file)
//    print(images.shape)  # (50000, 784)
let file = gzip.open("mnist.pkl.gz", "rb")
let (images, labels) = pickle.load(file).tuple2
print(images.shape) // (50000, 784)
```

As you can see, the syntax here is immediately understandable to a Python programmer: the major differences are that Swift requires values to be declared before use (with `let` or `var`) and that we chose to put [Python builtin functions](https://docs.python.org/3/library/functions.html) like `import`, `type`, `slice` etc under a `Python.` namespace (simply to avoid cluttering the global scope).  This is a result of a conscious balance between trying to make Python feel natural and familiar, while not compromising the global design of the Swift language.

This line is established through a simple requirement: we should not depend on *any Python-specific compiler or language features* to achieve Python interop - it should be completely implemented as a Swift library.  After all, while Python is incredibly important to the machine learning community, there are other dynamic languages (Javascript, Ruby, etc) that have strong footholds in other domains, and we don’t want each of these domains to impose an endless complexity creep onto the Swift language.

You can see the current implementation of our bridging layer in [Python.swift](https://github.com/apple/swift/blob/tensorflow/stdlib/public/Python/Python.swift).  This is pure Swift code that works with unmodified Swift 4.1.

### Limitations of this approach
Because we choose to embrace the dynamic nature of Python in Swift, we get both the pros and the cons that dynamic languages bring with them. Specifically, many Swift programmers have come to expect and depend on amazing code completion and appreciate the comfort of having the compiler catch typos and other trivial bugs for them at compile time.  In contrast, Python programmers do not have these affordances (instead, bugs are usually caught at runtime), and because we are embracing Python’s dynamic nature, Python APIs in Swift work the same way.

After careful consideration with the Swift community, it became clear that this is a balance: how much of the philosophy and value system of the Swift can be projected onto the Python library ecosystem... without breaking those things that are true and beautiful about Python and its libraries?  In the end, we concluded that a Python-centric model is the best compromise: we should embrace the fact that Python is a dynamic language, that it will never and can never have perfect code completion and error detection at static compile time.

It is important to observe that Python *does* have existing productivity tools that can find some bugs and provide nice tooling features like code completion.  These tools are generally based on unsound heuristics but are nonetheless extremely useful.  We would like for the heuristics used by these tools to be integrated into the Swift source tools and IDE ecosystem, but we need someone to step up to help build this out.  If you are interested, please [contact us](https://www.tensorflow.org/community/swift).

## How it works

We map Python’s dynamic type system into a **single** static Swift type named `PythonObject`, and allow `PythonObject` to take on any dynamic Python value at runtime (similar to the approach of [Abadi et al.](https://dl.acm.org/citation.cfm?id=103138)).  `PythonObject` corresponds directly to `PyObject*` used in the Python C bindings, and can do anything a Python value does in Python.   For example, this works just like you would expect in Python:

```swift
var x: PythonObject = 42  // x is an integer represented as a Python value.
print(x + 4)         // Does a Python addition, then prints 46.

x = "stringy now"    // Python values can hold strings, and dynamically change Python type!
print("super " + x)  // Does a Python addition, then prints "super stringy now".
```

Because we do not want to compromise the global design of Swift, we restrict all of Python behavior to expressions involving this `PythonObject` type.  This ensures that the semantics of normal Swift code remains unchanged, even if it is mixing, matching, interfacing, and intermingling with Python values.
### Basic interoperability
As of Swift 4.0, a reasonable level of basic interoperability was already directly achievable through existing language features: we simply define `PythonObject` as a Swift struct that wraps a private Swift `PyReference` class, allowing Swift to take over the responsibility for Python reference counting:

```swift
/// Primitive reference to a Python value.  This is always non-null and always
/// owning of the underlying value.
private final class PyReference {
  var state: UnsafeMutablePointer<PyObject>

  init(owned: UnsafeMutablePointer<PyObject>) {
    state = owned
  }

  init(borrowed: UnsafeMutablePointer<PyObject>) {
    state = borrowed
    Py_IncRef(state)
  }

  deinit {
    Py_DecRef(state)
  }
}

// This is the main type users work with.
public struct PythonObject {
  /// This is a handle to the Python object the PythonObject represents.
  fileprivate var state: PyReference
  ...
}
```

Similarly, we can implement `func +` (and the rest of the supported Python operators) on `PythonObject` in terms of the existing Python runtime interface.  Our implementation looks like this:

```swift
// Implement the + operator in terms of the standard Python __add__ method.
public static func + (lhs: PythonObject, rhs: PythonObject) -> PythonObject {
  return lhs.__add__.call(with: rhs)
}
// Implement the - operator in terms of the standard Python __sub__ method.
public static func - (lhs: PythonObject, rhs: PythonObject) -> PythonObject {
  return lhs.__sub__.call(with: rhs)
}
// Implement += and -= in terms of + and -, as usual.
public static func += (lhs: inout PythonObject, rhs: PythonObject) {
  lhs = lhs + rhs
}
public static func -= (lhs: inout PythonObject, rhs: PythonObject) {
  lhs = lhs - rhs
}
// etc...
```

We also make `PythonObject` conform to `Sequence` and other protocols, allowing code like this to work:

```swift
func printPythonCollection(_ collection: PythonObject) {
  for elt in collection {
    print(elt)
  }
}
```

Furthermore, because `PythonObject` conforms to `MutableCollection`, you get full access to the [Swift APIs for Collections](https://developer.apple.com/documentation/swift/mutablecollection), including functions like `map`, `filter`, `sort`, etc.
### Conversions to and from Swift values
Now that Swift can represent and operate on Python values, it becomes important to be able to convert between Swift native types like `Int` and `Array<Float>` and the Python equivalents.  This is handled by the `PythonConvertible` protocol - to which the basic Swift types like `Int` conform to, and to the Swift collection types like `Array` and `Dictionary` conditionally conform to (when their elements conform).  This makes the conversions fit naturally into the Swift model.

For example, if you know you need a Swift integer or you’d like to convert a Swift integer to Python, you can use:

```swift
let pyInt = PythonObject(someSwiftInteger)     // Always succeeds.
if let swiftInt = Int(somePythonValue) {  // Succeeds if the Python value is convertible to Int.
  print(swiftInt)
}
```

Similarly, aggregate types like arrays work exactly the same way:

```swift
// This succeeds when somePythonValue is a collection of values that are convertible to Int.
if let swiftIntArray = Array<Int>(somePythonValue) {
  print(swiftIntArray)
}
```

This fits exactly into the model that a Swift programmer would expect: failable conversions are projected into optional results (just like "string to int" conversions are), providing the safety and predictability that Swift programmers expect.

Finally, because you have access to the full power of Python, all the normal reflective capabilities of Python are directly available as well, including `Python.type`, `Python.id`, `Python.dir`, and the Python `inspect` module.

## Interoperability Challenges

The support above is possible because Swift’s design aims for and appreciates the goal of library-level syntactic extensibility of types.  We are also fortunate that Python and Swift share a very similar surface-level syntax for expressions (operators and function/method calls).  That said, there are a couple of challenges we encountered due to limits of Swift 4.0’s syntax extensibility and intentional design differences that we need to overcome.

### Dynamic member lookup

Though Swift 4.0 is a generally extensible language, primitive member lookup was not a library-extensible feature.  Specifically, given an expression of form `x.y`, the type of `x` was unable to control what happened when a member `y` was accessed on it.  If the type of `x` had statically declared a member named `y` then this expression would be resolved, otherwise it would be rejected by the compiler.

Within the constraints of Swift 4.0, [we built a binding](https://forums.swift.org/t/swift-python-interop-library-xcode-9-3b3-edition/) that worked around this.  For example, it was straightforward to implement member accesses in terms of Python’s `PyObject_GetAttrString` and `PyObject_SetAttrString`.  This allowed code like:

```swift
// Python: a.x = a.x + 1
a.set(member: "x", to: a.get(member: "x") + 1)
```

However, we can probably all agree that this does not achieve our goal of providing a natural and ergonomic interface to working with Python values!  Beyond that, it doesn’t provide any affordance for working with Swift L-Values: there is no way to spell the equivalent of `a.x += 1`.  Together these two problems were a significant expressivity gap.

After [discussion](https://forums.swift.org/t/pitch-introduce-user-defined-dynamic-member-lookup-types/7072) [with](https://forums.swift.org/t/pitch-2-introduce-user-defined-dynamic-member-lookup-types/7113) [the](https://forums.swift.org/t/proposal-introduce-user-defined-dynamic-member-lookup-types/7129) [Swift](https://forums.swift.org/t/dynamicmemberlookup-proposal-status-update/7358) [community](https://forums.swift.org/t/se-0195-introduce-user-defined-dynamic-member-lookup-types/8658), the solution to this problem is to allow library code to implement a fallback hook to handle failed member lookups.  This feature exists in many dynamic languages [including Objective-C](https://www.mikeash.com/pyblog/friday-qa-2009-03-27-objective-c-message-forwarding.html), and as such, we proposed and implemented [SE-0195: Introduce User-defined "Dynamic Member Lookup" Types](https://github.com/apple/swift-evolution/blob/master/proposals/0195-dynamic-member-lookup.md) which allows a static type to provide a fallback handler for unresolved lookups. This proposal was [discussed at length by the Swift community](https://forums.swift.org/t/se-0195-introduce-user-defined-dynamic-member-lookup-types/8658) through the Swift Evolution process, and was ultimately accepted.  It has been shipping since Swift 4.1.

As a result of this, our interoperability library is able to implement the following hook:

```swift
@dynamicMemberLookup
public struct PythonObject {
...
  subscript(dynamicMember member: String) -> PythonObject {
    get {
      return ... PyObject_GetAttrString(...) ...
    }
    set {
      ... PyObject_SetAttrString(...)
    }
  }
}
```

Which allows the above code to be simply expressed as:

```swift
// Python: a.x = a.x + 1
a.x = a.x + 1
```
... and the natural `a.x += 1` syntax works just like we expect.  This shows the huge benefit of being able to evolve the full stack of a language, its libraries, and applications together in order to achieve a goal.
### Dynamically callable types
In addition to member lookup, we have a similar challenge when it comes to calling values.  Dynamic languages often have the notion of ["callable" values](https://en.wikipedia.org/wiki/Callable_object), which can take an arbitrary signature, but Swift 4.1 has no support for such a thing.  For example, as of Swift 4.1, our interoperability library is able to work with Python APIs through an interface like this:

```swift
// Python: a = np.arange(15).reshape(3, 5)
let a = np.arange.call(with: 15).reshape.call(with: 3, 5)

// Python: d = np.array([1, 2, 3], dtype="i2")
let d = np.array.call(with: [6, 7, 8], kwargs: [("dtype", "i2")])
```

While it is possible to get things done with this, it is clearly not achieving our goal of convenience and ergonomics.

Evaluating this problem with the [Swift community](https://forums.swift.org/t/pitch-introduce-user-defined-dynamically-callable-types/7038) [and #2](https://forums.swift.org/t/pitch-2-introduce-user-defined-dynamically-callable-types/7112), we observe that Python and Swift support both named and unnamed arguments: the named arguments are passed in as a dictionary.  At the same time, Smalltalk-derived languages add an additional wrinkle: *method* references are the atomic unit, which include the base name of the method along with any keyword arguments.  While interoperability with this style of language is not important for Python, we want to make sure that Swift isn’t painted into a corner that precluded great interop with Ruby, Squeak, and other SmallTalk-derived languages.

Our current proposal, which has been discussed but not yet been implemented (and will need final approval by the Swift community), is to introduce a new [`@dynamicCallable` attribute](https://gist.github.com/lattner/a6257f425f55fe39fd6ac7a2354d693d) to indicate that a type (like `PythonObject`) can handle dynamic call resolution. The `@dynamicCallable` feature has been implemented and made available in the Python interop module.

```swift
// Python: a = np.arange(15).reshape(3, 5)
let a = np.arange(15).reshape(3, 5)

// Python: d = np.array([1, 2, 3], dtype="i2")
let d = np.array([6, 7, 8], dtype: "i2")
```
We think that this is pretty compelling, and does close the remaining expressivity and ergonomic gap that exists for these cases.  We believe that this feature will be a good solution for Ruby, Squeak, and other dynamic languages, as well as being a generally useful Swift language features that could be applicable to other Swift libraries.
### Exception handling vs error handling
Python’s approach to exception handling is similar to C++ and many other languages, where any expression can throw an exception at any time, and callers can choose to handle them (or not) independently.  In contrast, Swift’s [error handling approach](https://github.com/apple/swift/blob/master/docs/ErrorHandling.rst) makes "throwability" an explicit part of a method’s API contract and [forces callers to handle (or at least acknowledge)](https://github.com/apple/swift/blob/master/docs/ErrorHandlingRationale.rst) that an error can be thrown.

This is an inherent gap between the two languages, and we don’t want to paper over this difference with a language extension.  Our current solution to this builds on the observation that even though any function call *could* throw, most calls do not.  Furthermore, given that Swift makes error handling explicit in the language, it is reasonable for a Python-in-Swift programmer to also think about where they expect errors to be throwable and catchable.  We do this with an explicit `.throwing` projection on `PythonObject`.  Here’s an example:

```swift
  // Open a file.  If this fails, the program is terminated, just like an
  // unhandled exception in Python.

  // file = open("foo.txt")
  let file = Python.open("foo.txt")
  // blob = file.read()
  let blob = file.read()

  // Open a file, a thrown "file not found" exception is turned into a Swift error.
  do {
    let file = try Python.open.throwing("foo.txt")
    let blob = file.read()
    ...
  } catch {
    print(error)
  }
```

And of course, this integrates with all the normal mechanics provided by Swift error handling, including the ability to use `try?` if you want to handle the error but don’t care about details included in the exception.

## Current Implementation and Status

As mentioned above, our current implementation of the Python interoperability library is available on GitHub in the [Python.swift](https://github.com/apple/swift/blob/tensorflow/stdlib/public/Python/Python.swift) file.
In practice, we have found that it works nicely for many use cases. However, a few things that are missing that we need to continue developing and figure out:

Python slicing is more general than Swift’s slicing syntax.  Right now you can get full access to it through the `Python.slice(a, b, c)` function.  However, we should wire in the  normal `a...b` range syntax from Swift, and it might be interesting to consider implementing striding operators as an extension to that basic range syntax.
We need to investigate and settle on the right model to use for subclassing of Python classes.
There is currently no way to make a struct like `PythonObject` work with tuple pattern matching, so we use projection properties like `.tuple2`.  If this becomes a problem in practice, we can investigate adding this to Swift, but we currently don’t think it will be enough of a problem to be worth solving in the near term.

## Summary and Conclusion

We feel good about this direction and think that there are several interesting aspects of this work: it is great that there are no Python specific changes in the Swift compiler or language.  We are able to achieve good Python interoperability through a library written in Swift by composing Python-independent language features.  We believe that other communities will be able to compose the same feature set to directly integrate with the dynamic languages (and their runtimes) that are important to other communities (e.g. JavaScript, Ruby, etc).

Another interesting aspect of this work is that Python support is completely independent of the other TensorFlow and automatic differentiation logic we’re building as part of Swift for TensorFlow.  This is a generally useful extension to the Swift ecosystem that can stand alone, useful for server side development or anything else that wants to interoperate with existing Python APIs.

Finally, it is important to point out one major caveat in the context of Swift for TensorFlow: while you can directly call into an arbitrary Python API, the code partitioning analysis that automatically builds TensorFlow graphs for you cannot understand dynamic Python API calls.  While directly using APIs for TensorFlow (sessions, Keras, etc) through the Python interop layer is technically possible, it won't benefit from the compiler analyses and transformations we've built in Swift for TensorFlow.  Instead, we need to invent our own high-level APIs, and draw inspiration from Keras and other existing APIs.  Please see the [Graph Program Extraction](GraphProgramExtraction.md) document for more details about this.
