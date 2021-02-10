# Datasets

In many machine learning models, especially for supervised learning, datasets are a vital part of
the training process. Swift for TensorFlow provides wrappers for several common datasets within the
Datasets module in the [the models repository](https://github.com/tensorflow/swift-models). These
wrappers ease the use of common datasets with Swift-based models and integrate well with the
Swift for TensorFlow's generalized training loop.

## Provided dataset wrappers

These are the currently provided dataset wrappers within the models repository:

- [BostonHousing](https://github.com/tensorflow/swift-models/tree/main/Datasets/BostonHousing)
- [CIFAR-10](https://github.com/tensorflow/swift-models/tree/main/Datasets/CIFAR10)
- [MS COCO](https://github.com/tensorflow/swift-models/tree/main/Datasets/COCO)
- [CoLA](https://github.com/tensorflow/swift-models/tree/main/Datasets/CoLA)
- [ImageNet](https://github.com/tensorflow/swift-models/tree/main/Datasets/Imagenette)
- [Imagenette](https://github.com/tensorflow/swift-models/tree/main/Datasets/Imagenette)
- [Imagewoof](https://github.com/tensorflow/swift-models/tree/main/Datasets/Imagenette)
- [FashionMNIST](https://github.com/tensorflow/swift-models/tree/main/Datasets/MNIST)
- [KuzushijiMNIST](https://github.com/tensorflow/swift-models/tree/main/Datasets/MNIST)
- [MNIST](https://github.com/tensorflow/swift-models/tree/main/Datasets/MNIST)
- [MovieLens](https://github.com/tensorflow/swift-models/tree/main/Datasets/MovieLens)
- [Oxford-IIIT Pet](https://github.com/tensorflow/swift-models/tree/main/Datasets/OxfordIIITPets)
- [WordSeg](https://github.com/tensorflow/swift-models/tree/main/Datasets/WordSeg)

To use one of these dataset wrappers within a Swift
project, add `Datasets` as a dependency to your Swift target and import the module:

```swift
import Datasets
```

Most dataset wrappers are designed to produce randomly shuffled batches of labeled data. For
example, to use the CIFAR-10 dataset, you first initialize it with the desired batch size:

```swift
let dataset = CIFAR10(batchSize: 100)
```

On first use, the Swift for TensorFlow dataset wrappers will automatically download the original 
dataset for you, extract and parse all relevant archives, and then store the processed dataset in a 
user-local cache directory. Subsequent uses of the same dataset will load directly from the local
cache.

To set up a manual training loop involving this dataset, you'd use something like the following:

```swift
for (epoch, epochBatches) in dataset.training.prefix(100).enumerated() {
  Context.local.learningPhase = .training
  ...
  for batch in epochBatches {
    let (images, labels) = (batch.data, batch.label)
    ...
  }
}
```

The above sets up an iterator through 100 epochs (`.prefix(100)`), and returns the current epoch's 
numerical index and a lazily-mapped sequence over shuffled batches that make up that epoch. Within
each training epoch, batches are iterated over and extracted for processing. In the case of the 
`CIFAR10` dataset wrapper, each batch is a 
[`LabeledImage`](https://github.com/tensorflow/swift-models/blob/main/Datasets/ImageClassificationDataset.swift)
, which provides a `Tensor<Float>` containing all images from that batch and a `Tensor<Int32>` with
their matching labels.

In the case of CIFAR-10, the entire dataset is small and can be loaded into memory at one time, but
for other larger datasets batches are loaded lazily from disk and processed at the point where each
batch is obtained. This prevents memory exhaustion with those larger datasets.

## The Epochs API

Most of these dataset wrappers are built on a shared infrastructure that we've called the 
[Epochs API](https://github.com/tensorflow/swift-apis/tree/main/Sources/TensorFlow/Epochs). Epochs
provides flexible components intended to support a wide variety of dataset types, from text to
images and more.

If you wish to create your own Swift dataset wrapper, you'll most likely want to use the Epochs API
to do so. However, for common cases, such as image classification datasets, we highly recommend 
starting from a template based on one of the existing dataset wrappers and modifying that to meet
your specific needs.

As an example, let's examine the CIFAR-10 dataset wrapper and how it works. The core of the training
dataset is defined here:

```swift
let trainingSamples = loadCIFARTrainingFiles(in: localStorageDirectory)
training = TrainingEpochs(samples: trainingSamples, batchSize: batchSize, entropy: entropy)
  .lazy.map { (batches: Batches) -> LazyMapSequence<Batches, LabeledImage> in
    return batches.lazy.map{
      makeBatch(samples: $0, mean: mean, standardDeviation: standardDeviation, device: device)
  }
}
```

The result from the `loadCIFARTrainingFiles()` function is an array of
`(data: [UInt8], label: Int32)` tuples for each image in the training dataset. This is then provided
to `TrainingEpochs(samples:batchSize:entropy:)` to create an infinite sequence of epochs with 
batches of `batchSize`. You can provide your own random number generator in cases where you may want
deterministic batching behavior, but by default the `SystemRandomNumberGenerator` is used.

From there, lazy maps over the batches culminate in the 
`makeBatch(samples:mean:standardDeviation:device:)` function. This is a custom function where the 
actual image processing pipeline for the CIFAR-10 dataset is located, so let's take a look at that:

```swift
fileprivate func makeBatch<BatchSamples: Collection>(
  samples: BatchSamples, mean: Tensor<Float>?, standardDeviation: Tensor<Float>?, device: Device
) -> LabeledImage where BatchSamples.Element == (data: [UInt8], label: Int32) {
  let bytes = samples.lazy.map(\.data).reduce(into: [], +=)
  let images = Tensor<UInt8>(shape: [samples.count, 3, 32, 32], scalars: bytes, on: device)
  
  var imageTensor = Tensor<Float>(images.transposed(permutation: [0, 2, 3, 1]))
  imageTensor /= 255.0
  if let mean = mean, let standardDeviation = standardDeviation {
    imageTensor = (imageTensor - mean) / standardDeviation
  }
  
  let labels = Tensor<Int32>(samples.map(\.label), on: device)
  return LabeledImage(data: imageTensor, label: labels)
}
```

The two lines of this function concatenate all `data` bytes from the incoming `BatchSamples` into
a `Tensor<UInt8>` that matches the byte layout of the images within the raw CIFAR-10 dataset. Next, 
the image channels are reordered to match those expected in our standard image classification models
and the image data re-cast into a `Tensor<Float>` for model consumption.
	
Optional normalization parameters can be provided to further adjust image channel values, a process 
that is common when training many image classification models. The normalization parameter `Tensor`s
are created once at dataset initialization and then passed into `makeBatch()` as an optimization
to prevent the repeated creation of small temporary tensors with the same values.

Finally, the integer labels are placed in a `Tensor<Int32>` and the image / label tensor pair 
returned in a `LabeledImage`. A `LabeledImage` is a specific case of
[`LabeledData`](https://github.com/tensorflow/swift-models/blob/main/Support/LabeledData.swift), a
struct with data and labels that conform to the Eppch API's 
[`Collatable`](https://github.com/tensorflow/swift-apis/blob/main/Sources/TensorFlow/Epochs/Collatable.swift) protocol.

For more examples of the Epochs API in different dataset types, you can examine 
[the other dataset wrappers](https://github.com/tensorflow/swift-models/tree/main/Datasets)
within the models repository.
