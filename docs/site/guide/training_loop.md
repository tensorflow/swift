# Training loop

When training a machine learning model, it's common to have a loop where training data is ingested
(or generated), batches run through a model, gradients obtained, and the model updated via an
optimizer. While you can write a training loop of your own for each training application,
Swift for TensorFlow provides an experimental training loop abstraction that may simplify this
process.

The [`TrainingLoop`](https://github.com/tensorflow/swift-models/tree/main/TrainingLoop) module
within [the models repository](https://github.com/tensorflow/swift-models) contains the current
version of this experimental generalized training loop. It is structured in such a way as to
integrate with dataset wrappers that conform to the Epochs API for easy data ingestion, and to
automate the interaction of models, datasets, and optimizers with accelerator backends to achieve
optimal performance. Heavy customization of the training process can be achieved through the use
of callbacks.

Most image-based examples in the model repository have been converted to use this training loop
abstraction, as well as the supervised text model training examples. However, the training loop may
not be appropriate in its current design for all machine learning models.

The implementation of Swift for TensorFlow's generalized training loop is heavily influenced by
[fastai's Learner](https://docs.fast.ai/learner.html). For more on their design, please refer to
["fastai: A Layered API for Deep Learning"](https://arxiv.org/abs/2002.04688) and Sylvain Gugger's
presentation
["Fast.ai - An infinitely customizable training loop"](https://www.youtube.com/watch?v=roc-dOSeehM).

## Usage

The [ResNet-CIFAR10](https://github.com/tensorflow/swift-models/tree/main/Examples/ResNet-CIFAR10) 
example provides a good demonstration of how to use this training loop in practice. First, import
the module:

```swift
import TrainingLoop
```

then choose an accelerator backend by setting up a `Device`. In this case, we'll select the X10
XLA-based backend and use the first available accelerator:

```swift
let device = Device.defaultXLA
```

The next step is to configure the dataset, model, and optimizer to use with your training loop:

```swift
let dataset = CIFAR10(batchSize: 10, on: device)
var model = ResNet(classCount: 10, depth: .resNet56, downsamplingInFirstStage: false)
var optimizer = SGD(for: model, learningRate: 0.001)
```

and then set up the training loop:

```swift
var trainingLoop = TrainingLoop(
  training: dataset.training,
  validation: dataset.validation,
  optimizer: optimizer,
  lossFunction: softmaxCrossEntropy,
  metrics: [.accuracy])
```

The training loop assumes that the dataset you're using conforms to the Epochs API, and allows you
to specify which splits within the dataset to use for training and validation. Any loss function
can be used once placed into a compatible wrapper, such as `softmaxCrossEntropy` is 
[here](https://github.com/tensorflow/swift-models/blob/main/TrainingLoop/LossFunctions.swift).

The current metrics that can be captured include:

- `loss`
- `accuracy`
- `top5Accuracy`
- `matthewsCorrelationCoefficient`
- `perplexity`

Finally, to perform training, you call the following:

```swift
try! trainingLoop.fit(&model, epochs: 10, on: device)
```

This will train the model for 10 epochs using the accelerator backend we specified. Statistics will
be displayed during training to the console using an animated prompt.

## Callbacks

Customization of this generalized training loop occurs via the use of callbacks. These callbacks can
be hooked into various points within the loop.

Several built-in callbacks provide functionality that can be added to any training loop. These 
include:

- Logging statistics to comma-separated-value (CSV) files
- Adjusting the learning rate according to a custom schedule
- Monitoring and graphing training progress via TensorBoard

In addition to these, you can create your own custom callbacks to add a range of additional
functionality to a standard training loop.

### CSV logging

The [`CSVLogger`](https://github.com/tensorflow/swift-models/blob/main/TrainingLoop/Callbacks/CSVLogger.swift) 
class encapsulates a callback that will write out training statistics in a comma-separated-value 
format to a file of your choosing. This file will start with columns labeled `epoch`, `batch`, and 
whatever metrics you have enabled within your training loop. One row will then be written for each
batch, with the current values of those columns.

To add CSV logging to your training loop, add something like the following to an array of callbacks
provided to the `callbacks:` parameter for your `TrainingLoop`:

```swift
try! CSVLogger(path: "file.csv").log
```

As an example, the [`LeNet-MNIST` sample](https://github.com/tensorflow/swift-models/blob/main/Examples/LeNet-MNIST/main.swift#L52) 
uses this within its training loop.

### Learning rate schedules

It's common when training a model to change the learning rate provided to an optimizer during the
training process. This can be as simple as a linear decrease over time, or as complex as warmup and
decline cycles described by complicated functions.

The [`learningRateScheduler`](https://github.com/tensorflow/swift-models/blob/main/TrainingLoop/Callbacks/LearningRateScheduler/LearningRateScheduler.swift)
callback provides the means of describing learning rate schedules composed of different segments, 
each with their own distinct shape. This is accomplished by defining a
[`LearningRateSchedule`](https://github.com/tensorflow/swift-models/blob/main/TrainingLoop/Callbacks/LearningRateScheduler/LearningRateSchedule.swift)
composed of `ScheduleSegment`s that each have a `Shape` defined by a function, an initial learning
rate, and a final learning rate.

For example, the [BERT-CoLA sample](https://github.com/tensorflow/swift-models/blob/main/Examples/BERT-CoLA/main.swift)
uses a linear increase in the learning rate during a warmup period and a linear decrease after that.
To do this, the learning rate schedule callback is defined as follows:

```swift
learningRateScheduler(
  schedule: makeSchedule(
    [
      ScheduleSegment(shape: linear, startRate: 0, endRate: peakLearningRate, stepCount: 10),
      ScheduleSegment(shape: linear, endRate: 0)
    ]
  )
)
```

The two `ScheduleSegment`s define a learning rate that starts at 0 and increases linearly to
`peakLearningRate` over a series of 10 discrete steps, then starts at the final learning rate from
the previous step and decreases linearly to 0 by the end of the training process.

### TensorBoard integration

[TensorBoard](https://www.tensorflow.org/tensorboard) is a powerful visualization tool for 
monitoring model training, analyzing training when completed, or comparing training runs. Swift for
TensorFlow supports TensorBoard visualization through the use of the
[`TensorBoard`](https://github.com/tensorflow/swift-models/tree/main/TensorBoard) module in the 
models repository, which provides callbacks that log training metrics.

The [GPT2-WikiText2](https://github.com/tensorflow/swift-models/tree/main/Examples/GPT2-WikiText2)
sample illustrates how to add TensorBoard logging to your model training. First, import the
`TensorBoard` module. Then it's as simple as adding `tensorBoardStatisticsLogger()` to your
`TrainingLoop`'s `callbacks:` array.

By default, that will log each training run within a `run/tensorboard/stats` directory. To view this
within Tensorboard, run 

```sh
tensorboard --logdir ./run/tensorboard/stats
```

and TensorBoard should start a local server where you can view your training metrics. Training and
validation results should be shown separately, and each run has a unique timestamp to allow for
easy comparison between multiple runs of the same model.

The design of the Swift for TensorFlow TensorBoard integration was inspired by 
[tensorboardX](https://github.com/lanpa/tensorboardX). The TensorBoard callbacks directly create the
appropriate event and summary protocol buffers and write them within a log file during training.

### Custom callbacks

In addition to the built-in callbacks described above, you have the ability to customize the
function of training loops by creating your own callbacks. These callbacks are functions that 
have a signature similar to the following:

```swift
func customCallback<L: TrainingLoopProtocol>(_ loop: inout L, event: TrainingLoopEvent) throws
{
  if event == .updateStart {
    ...
  }
}
```

The training loop and associated state are passed in as the first parameter. The current part of
the loop that the callback is responding to is provided via `event`. The training loop event has
one of the following states, each corresponding to a different point in the loop's life cycle:

- `fitStart`
- `fitEnd`
- `epochStart`
- `epochEnd`
- `trainingStart`
- `trainingEnd`
- `validationStart`
- `validationEnd`
- `batchStart`
- `batchEnd`
- `updateStart`
- `inferencePredictionEnd`

Your callback function can choose to activate its logic on any combination of above states, which
allows for extracting data from or otherwise controlling the training loop in many ways.