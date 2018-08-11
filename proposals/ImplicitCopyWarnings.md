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
2. Within the program, only warn when data makes a round trip from one device to
   another device and back again.

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
heuristic.

## The round-trip-rule does not catch all slow programs

This rule obviously does not catch all slow programs. For example, a program
that frequently dumps large pieces of data from the GPU to the CPU might soak up
GPU memory with data waiting to be copied, and this rule will not catch that.

TOD: Justify!

## Issues with the heuristic

TODO: Fill this in!

We [recently eliminated warnings for scalar copies], because they cause a lot of
noise when used for control flow. For example, the following code emits warnings
about transferring the result of the while condition to the accelerator even
though the transfer doesn't slow or block anything:

```swift
public func train(steps: Int) -> Tensor<Double> {
  var weights = Tensor<Double>([0, 0, 0])
  var step = 0
  while step < steps {
    weights += 0.1
    step += 1
  }
  return weights
}
```



[recently eliminated warnings for scalar copies]: https://github.com/apple/swift/pull/18549
