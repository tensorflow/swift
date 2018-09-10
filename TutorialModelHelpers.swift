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
@differentiable(reverse, wrt: (.0), adjoint: adjSoftmaxCrossEntropy)
@inlinable @inline(__always)
func softmaxCrossEntropy(logits: Tensor<Float>, categoricalLabels: Tensor<Int32>) -> Float {
  return Raw.sparseSoftmaxCrossEntropyWithLogits(features: logits, labels: categoricalLabels).loss.mean()
}

@inlinable @inline(__always)
func adjSoftmaxCrossEntropy(logits: Tensor<Float>, categoricalLabels: Tensor<Int32>, primal: Float, seed: Float) -> Tensor<Float> {
  return seed * Raw.sparseSoftmaxCrossEntropyWithLogits(features: logits, labels: categoricalLabels).backprop
}

// TODO: Necessary because of SR-8699.
@differentiable(reverse, adjoint: adjAdd)
@inlinable @inline(__always)
func add(_ x: Tensor<Float>, _ y: Tensor<Float>) -> Tensor<Float> {
  return x + y
}

@inlinable @inline(__always)
func adjAdd(_ x: Tensor<Float>, _ y: Tensor<Float>, primal: Tensor<Float>, seed: Tensor<Float>) -> (Tensor<Float>, Tensor<Float>) {
  return (
    seed.broadcast(like: primal).unbroadcast(like: x),
    seed.broadcast(like: primal).unbroadcast(like: y))
}

// TODO: Add this as an extension to `Tensor` as `init(glorotUniform:)`
@usableFromInline func glorotUniform(_ a: Int32, _ b: Int32) -> Tensor<Float> {
    let minusOneToOne = 2 * Tensor<Float>(randomUniform: [a, b]) - 1
    return sqrt(Tensor(6 / Float(a + b))) * minusOneToOne
}

