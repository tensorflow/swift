# Implicit Copy Warning Improvements

* Author: [Marc Rasi](https://github.com/marcrasi)

## Introduction

Currently, implicit copy warnings are very noisy. For example, [this simple
model] produces [these warnings]. (See the "Performance Predictability" section
of [Graph Program Extraction] for more information about implicit copy
warnings).

I propose that we clean up the warnings as follows:
1. Emit no warnings for data transferred while the program is starting (e.g.
   training data being copied to the GPU) or ending (e.g. final weights being
   copied to the CPU).
2. Within the program, only warn when data makes a round trip between devices:
   when a piece of data moves from device A to device B, then a computation
   using that data happens on device B, and then the result of that computation
   moves back to device A.

Concretely, this proposal eliminates all warnings in [the example].

Since the round-trip-rule might be hard to implement, I also propose that we
initially implement a simple heuristic that approximates the round-trip-rule:
Warn for all transfers from the host to the accelerator, but do not warn for any
transfers from the accelerator to the host.

Since all round trips involve a transfer from the host to the accelerator, the
heuristic catches all transfers that the round-trip-rule catches.

[Graph Program Extraction]: https://github.com/tensorflow/swift/blob/master/docs/GraphProgramExtraction.md
[this simple model]: ./ImplicitCopyWarnings/LinearRegression.swift
[the example]: ./ImplicitCopyWarnings/LinearRegression.swift
[these warnings]: ./ImplicitCopyWarnings/LinearRegression-warnings.txt

## Justification

The main purpose of implicit copy warnings is to alert the user when the Swift
for TensorFlow programming model causes their program to compile in an
unexpected and surprising way.

Users expect their programs to start off by transferring data to an accelerator,
they expect their programs to occasionally send debugging or status information
(e.g. model loss) back to the CPU for display or logging purposes, and they
expect their programs to send results back to the CPU when they finish. So we
should not produce warnings for any of these things. For example, this code,
which does all of those things, should not produce any warnings:

```swift
public func train(inputs: Tensor<Float>, outputs: Tensor<Float>, initialWeights: Tensor<Float>) -> Tensor<Float> {
  var weights = initialWeights
  for step in 0...1000 {
    let predictions = inputs • weights
    let errors = predictions - outputs
    let dweights = (errors * inputs).sum(alongAxes: 0).transposed()
    weights -= 0.01 * dweights

    if (step % 100 == 0) {
      print("Current weights: \(weights)") // Notice that `weights` gets copied to the CPU
    }
  }
  return weights
}
```

What we want to avoid is unexpectedly blocking users' computations. This can
happen when the user writes some code that (unbeknownst to them) forces some
computation to happen on the CPU before computation on the accelerator can
proceed. For example, suppose that `cpuOnlyComputation` runs a computation that
can only happen on the CPU. Then this training loop blocks on data transfer and
CPU computation every iteration:

```swift
public func train(inputs: Tensor<Float>, outputs: Tensor<Float>, initialWeights: Tensor<Float>) -> Tensor<Float> {
  var weights = initialWeights
  for step in 0...1000 {
    let predictions = cpuOnlyComputation(inputs • weights)
    let errors = predictions - outputs
    let dweights = (errors * inputs).sum(alongAxes: 0).transposed()
    weights -= 0.01 * dweights

    if (step % 100 == 0) {
      print("Current weights: \(weights)")
    }
  }
  return weights
}
```

We should emit a warning in the above code so that the user is aware that their
training loop is blocking on data transfer and CPU computation.

The round-trip-rule achieves exactly what we want in these examples! So does the
heuristic of warning for all transfers from the host to the accelerator.

## False-positive / False-negative tradeoff

The round-trip-rule does not catch all slowness related to implicit copies. For
example, a program that frequently dumps large pieces of data from the GPU to
the CPU might soak up GPU memory with data waiting to be copied, and the
round-trip-rule will not catch that.

However, the round-trip-rule does capture what I currently believe will be the
main source of performance unpredictability (accidentally writing code that
moves a piece of a computation onto a different device), so I propose that it's
a good initial balance between false positives and false negatives.

After we gain more experience with Swift models, we can revisit implicit copy
warnings and see whether the balance still appears to be good.

## Issues with the heuristic

The heuristic (warn for all transfers from the host to the accelerator) can
produce false positive warnings for harmless transfers from the host to the
accelerator. One common situation where this happens is when the host calculates
some simple control flow conditions and sends them to the accelerator. For
example:

```swift
public func example(steps: Int) -> Tensor<Float> {
  var result: Tensor<Float> = Tensor(zeros: [10, 10])
  vat step: Int = 0
  while step < steps {
    if step % 2 == 0 {
      result += 1
    } else {
      result += 2
    }
    step += 1
  }
}
```

If `step < steps` and `step % 2 == 0` get evaluated on the host and the boolean
results get copied over to the accelerator, then the heuristic will warn about
implicit copies. But these implicit copies are harmless because the host can
quickly run through a bunch of iterations and queue up a bunch of booleans for
the accelerator to consume.

Without implementing the true round-trip-rule, we can denoise the warnings in
that situation by suppressing warnings for scalar transfers. But the
round-trip-rule suppresses those warnings in a cleaner and more reliable way, so
I propose that we eventually do implement the round-trip-rule.
