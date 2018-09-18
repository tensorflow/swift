/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
/// https://www.apache.org/licenses/LICENSE-2.0
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.

/// This file contains some APIs that are important for the tutorial that are
/// missing from the standard library. Eventually, we will eliminate this file
/// by extending the standard library.

// TODO: Add this to the standard library? It's a pretty useful op for
// classification problems.
@inlinable
@differentiable(reverse, wrt: (.0), 
                primal: _primalSoftmaxCrossEntropy, 
                adjoint: _adjointSoftmaxCrossEntropy)
func softmaxCrossEntropy(logits: Tensor<Float>, categoricalLabels: Tensor<Int32>) -> Float {
  return Raw.sparseSoftmaxCrossEntropyWithLogits(features: logits, 
                                                 labels: categoricalLabels).loss.mean()
}

@inlinable
internal func _primalSoftmaxCrossEntropy(logits: Tensor<Float>, 
                                         categoricalLabels: Tensor<Int32>) -> (Tensor<Float>, Float) {
  let (loss, grad) = Raw.sparseSoftmaxCrossEntropyWithLogits(features: logits, 
                                                             labels: categoricalLabels)
  return (grad, loss.mean())
}

@inlinable
internal func _adjointSoftmaxCrossEntropy(logits: Tensor<Float>, 
                                          categoricalLabels: Tensor<Int32>, 
                                          checkpointedGrad: Tensor<Float>, 
                                          originalResult: Float, 
                                          seed: Float) -> Tensor<Float> {
  return checkpointedGrad
}

extension Tensor where Scalar : BinaryFloatingPoint,
                       Scalar.RawSignificand : FixedWidthInteger {
  @inlinable
  init(glorotUniform shape: TensorShape) {
    let minusOneToOne = 2 * Tensor(randomUniform: shape) - 1
    self = sqrt(Tensor(6 / Scalar(shape.contiguousSize))) * minusOneToOne
  }
}


