# Model Summaries

A summary provides details about the architecture of a model, such as layer
types and shapes.

The design proposal can be found [here][design]. This
implementation is a WIP, so please file an [Issue][new_issue] with
enhancements you would like to see or problems you run into.

**Note:** Model summaries are currently supported on the X10 backend only.

## Viewing a model summary

Create an X10 device and model.

```
import TensorFlow

public struct MyModel: Layer {
  public var dense1 = Dense<Float>(inputSize: 1, outputSize: 1)
  public var dense2 = Dense<Float>(inputSize: 4, outputSize: 4)
  public var dense3 = Dense<Float>(inputSize: 4, outputSize: 4)
  public var flatten = Flatten<Float>()

  @differentiable
  public func callAsFunction(_ input: Tensor<Float>) -> Tensor<Float> {
    let layer1 = dense1(input)
    let layer2 = layer1.reshaped(to: [1, 4])
    let layer3 = dense2(layer2)
    let layer4 = dense3(layer3)
    return flatten(layer4)
  }
}

let device = Device.defaultXLA
let model0 = MyModel()
let model = MyModel(copying: model0, to: device)
```

Create an input tensor.

```
let input = Tensor<Float>(repeating: 1, shape: [1, 4, 1, 1], on: device)
```

Generate a summary of your model.

```
let summary = model.summary(input: input)
print(summary)
```

```
Layer                           Output Shape         Attributes
=============================== ==================== ======================
Dense<Float>                    [1, 4, 1, 1]
Dense<Float>                    [1, 4]
Dense<Float>                    [1, 4]
Flatten<Float>                  [1, 4]
```

**Note:** the `summary()` function executes the model in order to obtain
details about its architecture.


[design]: https://docs.google.com/document/d/1hEhMiwLtuzsN3RvIC3FAh6NvtTimU8o_qdzMkGvntVg/view
[new_issue]: https://github.com/tensorflow/swift-apis/issues/new
