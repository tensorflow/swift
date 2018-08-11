import TensorFlow

public struct LinearModel {
  var w: Tensor<Float>
  var b: Tensor<Float>

  init(inputSize: Int32) {
    w = Tensor<Float>(randomUniform: [inputSize, 1])
    b = Tensor<Float>(randomUniform: [1])
  }
}

extension LinearModel {
  public func predict(inputs: Tensor<Float>) -> Tensor<Float> {
    return inputs • w + b
  }

  public func loss(inputs: Tensor<Float>, outputs: Tensor<Float>) -> Float {
    let predictions = predict(inputs: inputs)
    return (predictions - outputs).squared().mean()
  }

  public mutating func trainStep(inputs: Tensor<Float>, outputs: Tensor<Float>,
                                 learningRate: Float) {
    let predictions = predict(inputs: inputs)

    let errors = predictions - outputs
    let dw = (errors * inputs).sum(alongAxes: 0).transposed()
    let db = errors.sum(squeezingAxes: 0)

    w -= learningRate * dw
    b -= learningRate * db
  }

  public mutating func train(inputs: Tensor<Float>, outputs: Tensor<Float>, learningRate: Float,
                             steps: Int) {
    print("Training for \(steps) steps")
    for i in 0..<steps {
      trainStep(inputs: inputs, outputs: outputs, learningRate: learningRate)
      if i % (steps / 10) == 0 || i == steps - 1 {
        print("Current model: \(self), training loss: \(loss(inputs: inputs, outputs: outputs))")
      }
    }
  }
}

public func trainSampleModel() -> LinearModel {
  // The output is the sum of the two inputs. But the inputs are noisy.
  let inputSize: Int32 = 2
  let trainInputs = Tensor<Float>([
    [1, 1],
    [-1, 1],
    [5, 5],
    [2, 3]
  ]) + 0.1 * Tensor(randomNormal: [4, 2])
  let trainOutputs = Tensor<Float>([
    [2],
    [0],
    [10],
    [5]
  ])

  var model = LinearModel(inputSize: inputSize)
  model.train(inputs: trainInputs, outputs: trainOutputs, learningRate: 0.01, steps: 1000)
  return model
}

public func testSampleModel(model: LinearModel) {
  // The output is the sum of the two inputs. But the inputs are noisy.
  let testInputs = Tensor<Float>([
    [3, 10],
    [-5, 6],
    [4, 2],
    [0, 6]
  ]) + 0.1 * Tensor(randomNormal: [4, 2])
  let testOutputs = Tensor<Float>([
    [13],
    [1],
    [6],
    [6]
  ])

  let loss = model.loss(inputs: testInputs, outputs: testOutputs)
  let predictions = model.predict(inputs: testInputs)
  print("Testing loss: \(loss)")
  print("Testing predictions: \(predictions)")
  print("Correct outputs: \(testOutputs)")
}

let model = trainSampleModel()
print("")
testSampleModel(model: model)
