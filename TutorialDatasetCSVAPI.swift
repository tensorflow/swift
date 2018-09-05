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

/// This file contains some special-case APIs that make parts of the tutorial
/// work even though we do not have general APIs. Soon, we will have general
/// APIs replacing this.

/// Initialize a (features: Tensor<Float>, labels: Tensor<Int32>) dataset from
/// a CSV file.
extension Dataset where Element == (Tensor<Float>, Tensor<Int32>) {
  @inlinable @inline(__always)
  public init(contentsOfCSVFile: String, hasHeader: Bool,
              featureColumns: [Int],
              labelColumns: [Int]) {
    // We can't make `np` a private top-level variable in this file, because
    // this function is @inlinable.
    let np = Python.import("numpy")

    let featuresNp = np.loadtxt(contentsOfCSVFile, delimiter: ",",
                                skiprows: hasHeader ? 1 : 0,
                                usecols: featureColumns,
                                dtype: Float.numpyScalarTypes.first!)
    guard let featuresTensor = Tensor<Float>(numpyArray: featuresNp) else {
      // This should never happen, because we construct numpyArray in such a
      // way that it should be convertible to tensor.
      fatalError("np.loadtxt result can't be converted to Tensor")
    }

    let labelsNp = np.loadtxt(contentsOfCSVFile, delimiter: ",",
                              skiprows: hasHeader ? 1 : 0,
                              usecols: labelColumns,
                              dtype: Int32.numpyScalarTypes.first!)
    guard let labelsTensor = Tensor<Int32>(numpyArray: labelsNp) else {
      // This should never happen, because we construct numpyArray in such a
      // way that it should be convertible to tensor.
      fatalError("np.loadtxt result can't be converted to Tensor")
    }

    self.init(elements: (featuresTensor, labelsTensor))
  }
}
