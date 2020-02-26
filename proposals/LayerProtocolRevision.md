# Layer Protocol - Training and Concurrent Testing

* Author: [@ewconnell](https://github.com/ewconnell)

## Introduction
This document discusses the requirements and proposed design changes to enable concurrent testing while training. It also discusses problems with use of the _LearningPhaseIndicator_ class in the current design.

## Performance
Significant training time improvement can be achieved by performing model test passes concurrently, allowing training to continue uninterrupted. The larger the training sample, number of samples in the test set, and more expensive the model design, the greater the benefit. Concurrent test passes can utilize idle GPU capacity, utilize additional GPUs, or be distributed to other nodes.

The current S4TF implementation does allow this to a limited degree. The following example runs correctly. In this case very little benefit is achieved because the S4TF training pass is currently much slower than the inference pass. In Netlib a training pass is very fast, so I was able to confirm that a concurrent test pass achieves a significant performance gain. The following is an example of a concurrent training loop that currently works with the simple addition of a _DispatchQueue_ and _DispatchGroup_. Since Layer is a struct, models copy correctly. As training proceeds the learned parameters mutate, making the copies independent.
```swift
var model = MNISTClassifier()
let optimizer = SGD<MNISTClassifier, Float>(learningRate: 0.1, momentum: 0.9)
let batchSize: Int32 = 60
let testBatchSize: Int32 = 1000
let trainingIterations: Int32 = trainingImages.shape[0] / batchSize
let epochs = 10
let testQueue = DispatchQueue(label: "testQueue")
let testGroup = DispatchGroup()

func minibatch<T>(_ x: Tensor<T>, size: Int32, batchIndex: Int32) -> Tensor<T> {
  let start = batchIndex * size
  return x[start..<start + size]
}

print("Begin training for \(epochs) epochs" )
let start = Date()

for epoch in 0..<epochs {
  var totalLoss: Float = 0
  // train
  for i in 0..<trainingIterations {
    let images = minibatch(trainingImages, size: batchSize, batchIndex: i)
    let labels = minibatch(oneHotTrainingLabels, size: batchSize, batchIndex: i)

    let gradients = gradient(at: model) { model -> Tensor<Float> in
      let logits = model.applied(to: images)
      let batchLoss = softmaxCrossEntropy(logits: logits, labels: labels)
      totalLoss += batchLoss.scalarized()
      return batchLoss
    }
    optimizer.update(&model.allDifferentiableVariables, along: gradients)
  }
  // test
  testQueue.async(group: testGroup) {
    var totalCorrect: Int32 = 0
    for i in 0..<Int32(10) {
      let images = minibatch(testImages, size: testBatchSize, batchIndex: i)
      let labels = minibatch(numericTestLabels, size: testBatchSize, batchIndex: i)
      let predictions = model.infer(from: images)
      let correct = predictions.argmax(squeezingAxis: 1) .== labels
      totalCorrect += Tensor<Int32>(correct).sum().scalarized()
    }

    let accuracy = Float(totalCorrect) / Float(numericTestLabels.shape[0])
    print("epoch \(epoch) accuracy: \(accuracy) loss: \(totalLoss)")
  }
}
testGroup.wait()
print("Training complete: \(String(timeInterval: Date().timeIntervalSince(start)))")
```
## Copying Layers and the LearningPhaseIndicator
Some operators such as BatchNorm and Dropout need to behave differently depending on whether they are performing training or inference. The current design defines the LearningPhaseIndicator class which is intended to behave like a global variable scoped to a single model. The training loop would toggle the _.training_ value depending on whether training or inference is being performed.

The examples I saw in [tensorflow swift-models](https://github.com/tensorflow/swift-models) had the LearningPhaseIndicator declared and manipulated separately from the model it was affecting. One object having a side effect on another is problematic. Declaring it as a member of the root layer would have been better. In any case this design won’t work because as soon as you copy a model, the same LearningPhaseIndicator will be affecting both models. This would make it impossible to perform concurrent testing, or work with model copies in general. I don’t believe there is any clean way to have a pseudo global variable scoped to a Layer tree. I ran into the same design problem several years ago.

## Suggested Design Change
A simple and performative solution is to modify the Layer _applied(to:_ API to include a training parameter. Perhaps add an extension function to drop the parameter when calling layers that don’t make a distinction.
```swift
public protocol Layer: Differentiable & KeyPathIterable
    where AllDifferentiableVariables: KeyPathIterable {
    /// The input type of the layer.
    associatedtype Input: Differentiable
    /// The output type of the layer.
    associatedtype Output: Differentiable

    /// Returns the output obtained from applying to an input.
    @differentiable(wrt: (self, input))
    func applied(to input: Input, training: Bool) -> Output
}

public extension Layer {
  func applied(to input: Input) -> Output {
    return applied(to: input, training: false)
  }
}
```
Layer implementations such as BatchNorm can easily switch functionality in a readable way.
```swift
public func applied(to input: Tensor<Scalar>, training: Bool) -> Tensor<Scalar> {
  if training {
    return applyTraining(to: input)
  } else {
    return applyInference(to: input)
  }
}
```
Layer pass through would look clean as well
```swift
public func applied(to input: Tensor<Float>, training: Bool) -> Tensor<Float> {
  let h0 = conv1.applied(to: input)
  let h1 = maxPool1.applied(to: h0)
  let bn = batchNorm.applied(to: h1, training: training)
  let h2 = conv2.applied(to: bn)
  let h3 = maxPool2.applied(to: h2)
  let dense1InputShape = Tensor<Int32>([h3.shape[0], 800])
  let h4 = dense1.applied(to: h3.reshaped(toShape: dense1InputShape))
  return dense2.applied(to: h4)
}
```
A simple model declaration might look like
```swift
public struct MNISTClassifier: Layer {
  let maxPool1: MaxPool2D<Float>
  let maxPool2: MaxPool2D<Float>
  var batchNorm: BatchNorm<Float>
  var conv1: Conv2D<Float>
  var conv2: Conv2D<Float>
  var dense1: Dense<Float>
  var dense2: Dense<Float>

  public init() {
    conv1 = Conv2D(filterShape: (5, 5, 1, 20), padding: .valid)
    maxPool1 = MaxPool2D(poolSize: (2, 2), strides: (2, 2), padding: .valid)
    batchNorm = BatchNorm(featureCount: 20)
    conv2 = Conv2D(filterShape: (5, 5, 20, 50), padding: .valid)
    maxPool2 = MaxPool2D(poolSize: (2, 2), strides: (2, 2), padding: .valid)
    dense1 = Dense(inputSize: 800, outputSize: 500, activation: relu)
    dense2 = Dense(inputSize: 500, outputSize: 10, activation: { $0 })
  }

  @differentiable(wrt: (self, input))
  public func applied(to input: Tensor<Float>, training: Bool) -> Tensor<Float> {
    let h0 = conv1.applied(to: input)
    let h1 = maxPool1.applied(to: h0)
    let bn = batchNorm.applied(to: h1, training: training)
    let h2 = conv2.applied(to: bn)
    let h3 = maxPool2.applied(to: h2)
    let dense1InputShape = Tensor<Int32>([h3.shape[0], 800])
    let h4 = dense1.applied(to: h3.reshaped(toShape: dense1InputShape))
    return dense2.applied(to: h4)
  }

  public func infer(from input: Tensor<Float>) -> Tensor<Float> {
    return softmax(applied(to: input))
  }
}
```
The revised training loop would only need to specify the _training_ parameter and would now look like:
```swift
for i in 0..<trainingIterations {
  let images = minibatch(trainingImages, size: batchSize, batchIndex: i)
  let labels = minibatch(oneHotTrainingLabels, size: batchSize, batchIndex: i)
  let gradients = gradient(at: model) { model -> Tensor<Float> in
    // set training to true
    let logits = model.applied(to: images, training: true)
    let batchLoss = softmaxCrossEntropy(logits: logits, labels: labels)
    totalLoss += batchLoss.scalarized()
    return batchLoss
  }
  optimizer.update(&model.allDifferentiableVariables, along: gradients)
}
```
## Conclusion
This minor design change will
* Eliminate the need for the LearningPhaseIndicator class
* Fix the model copying problem
* Enable concurrent testing to improve performance

The implementation change will likely affect a lot of the codebase as the _applied(to:_ function is central to automatic differentiation.

