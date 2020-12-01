# Graph Program Extraction: One Graph Function per Host Function

* Author: [@eaplatanios](https://github.com/eaplatanios)

## Introduction

This document aims to serve as complementary to the original graph program extraction (GPE) [whitepaper](<https://github.com/tensorflow/swift/blob/main/docs/GraphProgramExtraction.md>). It is a proposal for a general high-level design for performing GPE. Even though the document uses Swift and TensorFlow as the running use case, the proposed design is more general and could be used with other languages and frameworks. It is also a very early draft but the hope is that it will stimulate discussion and evolve into a few well-defined and well-specified design guidelines.

## Desired Features

As described in the GPE whitepaper, GPE is effectively a [program slicing](https://en.wikipedia.org/wiki/Program_slicing) method. This can be thought of as follows: working with Swift and TensorFlow means that we work with two different languages that get executed as two separate programs that can communicate when needed. One program is the main Swift program that also serves as the entrypoint of execution. The other is the _implicitly constructed_ TensorFlow graph that gets executed by the TensorFlow runtime. Ideally we would like to:

1. Have a single entrypoint for the Swift program and a single entrypoint for the TensorFlow program (i.e., use a single TF graph for the whole program, and a single session that starts executing parts of the graph at the same time that the Swift program starts executing things on the Swift-side).
2. Allow for communication between the two programs, wherever necessary, and make that communication explicit to the user of the API, without it being cumbersome to them, or requiring boilerplate code.
3. Avoid the need for aggressive inlining of all TensorFlow-related code on the Swift-side (which is what is currently happening in the Swift implementation).
4. Allow for easy packaging of Swift for TF libraries that can be used _efficiently_ by client code. By _efficiently_ here we mean that the constructed TF graph will not contain unused code from the imported libraries.
5. Try to make the _between-communication_ parts of each program as large as possible, as this would allow for more optimizations on either side. We will refer to this as _partitioning_ the two programs into as large chunks as possible, from now on.

This document mainly discusses points 1-4, but also touches upon 5, without going into much detail.

## Tackling Point 1: Single Entrypoints for the Two Programs

Having a single entrypoint for the Swift program is not worth discussing as that is already _handled_ by the fact that, in our design, the Swift program is the one that controls execution anyway, and can invoke TF programs, as needed. In order to be able to have a single entrypoint for the TF program, we first discuss how we construct the graph, such that we have a single TF graph, and then we discuss how the session executing that graph is managed.

### Single TF Graph

We construct the TF graph by _walking through_ the Swift program and creating a program with the exact same structure, but keeping only the TF-relevant parts. This means that we start at the top-level Swift code, that will be executed when we execute the Swift program. For now, we ignore functions as that will be discussed when we tackle point 3.

For all top-level code we check where `Tensor`s are used and how and we built a TF graph, based on the methods outlined in the GPE whitepaper. `Tensor`s that are created on the Swift-side are handled by the TF graph in the way described in the section tackling point 2. After building the TF graph in this manner, we collect all sink nodes in the TF graph, whether those are nodes that send tensors back to the Swift program, or simply nodes that only have a side-effect on the TF side, and we create a new TF `group` node that we call the `sink` node. This means that once the `sink` node finishes executing in TF, all TF-related computation for the current Swift for TF program will have finished executing and so it can be thought of as the TF _endpoint_.

We have ignored functions that use TF for now, but we will discuss those in the section devoted to point 3.

### Single TF Session

Given the single TF graph we have built for the current Swift for TF program, we can then go ahead and add the following in the beginning of the top-level Swift program code (on the Swift side):

1. Create a new TF session (with any desirable configuration).
2. Add a call to `session.run(sink)`.

This last call will start execution of the TF program, so that it is running in parallel with the Swift program. It allows all parts of the graph that do not depend on communicating with Swift at any point in time, to be executed in parallel with the main Swift program. The fact that we end up with a single TF session means that it becomes easy to manage the session configuration and to profile the TF program performance. Furthermore, no two TF sessions have to fight for the same resources. It also makes this program slicing approach cleaner in that there is only two programs running at any point in time, a single Swift program and its corresponding TF program.

## Tackling Point 2: Communication Between Swift and TF

Communication between Swift and TF can be handled in a clean manner, by following the same principles.

1. ___Swift -> TF:___ The TF program deals with `Tensor` objects. Therefore, whenever a `Tensor` object is constructed on the Swift side, and later used by TF ops that require tensors, a corresponding `SendToTF` op is added to the graph. This actually consists of two ops: (i) an `Enqueue` op, and a (ii) `Dequeue` op to a blocking queue. The `Dequeue` op will be used as the `Tensor` object representation for TF ops consuming it later on, and a `session.run(...)` call will be added to the Swift side, enqueueing the constructed tensor that will be sent to TF.
2. ___TF -> Swift:___ `Tensor` objects allow for various ways to obtain their content, or a reference to them. One proposal could be to have methods like `.scalar`, `.toArray`, `.iterator`, and `.handle`, that return Swift-typed values. Whenever these are used, data needs to be transferred from TF to Swift and so we would add a `ReceiveFromTF` op to the graph. This actually again consists of two ops: (i) an `Enqueue` op, and a (ii) `Dequeue` op to a blocking queue. The `Enqueue` op will be added to the TF graph, enqueueing the corresponding TF tensor (or its handle, for example) to the queue. At the same time, a `session.run(...)` call will be added to the Swift side, dequeueing the TF content that is to be received from the graph. These method calls will be required to be made explicitly from the library user and will not be added automatically by the Swift compiler, in order to avoid confusion and potential inefficiencies.

## Tacking Point 3: Handling Functions that use TF

Currently, Swift for TF handles all Swift functions that use TF by aggressively inlining them. This can cause lots of issues, including an exploding size of the compiled code, as well as limited supported for recursion (note that TF graph functions themselves support recursion and thus we should be able to support it on our side too). Here we suggest we use TF graph functions to handle Swift functions that use TF. We propose the following high-level design: all Swift functions that use TF will be compiled into two separate functions:

1. ___Swift Function:___ The Swift code part of the compiled function that contains all computation that needs to happen on the Swift side. Note that in the case that this is a pure TF function (using only TF ops), then this function could be compiled to a no-op, or optimized away entirely.
2. ___TF Graph Function:___ The TF part of the compiled function that is a TF `FunctionDef` protobuf message which contains the extracted TF graph for the compiled function.

The calling code will be invoking both functions in parallel, in its two generated programs -- the Swift program and the TF program, respectively. Note that for the TF program, the invocation will consist of simply adding the corresponding `FunctionDef` to the graph function library and creating an op representing that function call.

Here we omit details related to handling mixed Swift and TF arguments and also related to propagation such function calls which means that one function invocation may require multiple `FunctionDef`s to be added to the graph, as these can be handled relatively easily, and would distract from the main proposed idea.

## Tackling Point 4: Packaging Libraries

Note that due to our way of tackling point 3, packaging compiled libraries becomes very easy. For Swift code that is not top-level (meaning that it won't be executed when running the compiled Swift code), we only package the `FunctionDef`s for Swift functions that use TF, alongwise the SIL of their corresponding Swift functions. This might require us to also store an index that keeps track of arguments to those functions and correspondence between Swift and TF functions. There is no main TF graph being constructed in this case as, as already mentioned when tackling point 1, we only ever construct a single TF graph when compiling top-level Swift code.

This is really beneficial because it allows us to avoid aggressive inlining and thus shrink the constructed single TF graph, to only contain the `FunctionDef`s, for the functions actually used in the top-level code that will be executed. It also allows all sorts of optimizations to be performed when compiling that top-level code, because the SIL representation for those functions is also stored, as is the `FunctionDef`.

## Tackling Point 5: Optimizations

Many of the current optimizations that Swift for TF performs and aims to perform, can still be achieved due to the SIL and the `FunctionDef`s being distributed with compiled libraries. Furthermore, a simpler approach may be to let the Swift compiler optimize the Swift-side code in isolation, and the same for the TF graph compiler (assuming that the TF graph compiler can also perform inlining of TF graph functions, if needed). This should already allow for lots of optimizations and would most likely already result in much more performant code than would have been obtained using TF eager mode, for example.

Note also that a lot of `SendToTF` and `ReceiveFromTF` ops can be avoided by being smart as to how the graph is wired and by allowing constant expressions on the Swift side to be implicitly converted to constant tensors in the TF graph, if needed.

## Questions for Discussion

1. How should we handle send/receive ops? More specifically, we may want to pass around tensor handles and/or tensor content and I believe the answer to this question should be aware of this distinction.
2. How do we package TF graph functions and host functions such that certain optimizations can still be performed on the user code (as in user of a Swift for TF library)?
3. What kind of optimizations do we want to allow/consider?

## Conclusion

I believe this document provides a good starting point for provided a standard high-level design for graph program extraction (GPE), that is simpler and more modular than the current approach in the Swift for TF implementation. It is a very early draft but the hope is that it will stimulate discussion and evolve into a few well-defined and well-specified design guidelines.
