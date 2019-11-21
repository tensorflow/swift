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

/// This file contains some special-case APIs that make parts of the tutorial work even though we
/// do not have general APIs. Soon, we will have general APIs replacing this.

/// Conform `IrisBatch` to `TensorGroup` so that we can load it into a `Dataset`.
extension IrisBatch: TensorGroup {
    public static var _typeList: [TensorDataType] = [
        Float.tensorFlowDataType,
        Int32.tensorFlowDataType
    ]
    public static var _unknownShapeList: [TensorShape?] = [nil, nil]
    public var _tensorHandles: [_AnyTensorHandle] {
        fatalError("unimplemented")
    }
    public func _unpackTensorHandles(into address: UnsafeMutablePointer<CTensorHandle>?) {
        address!.advanced(by: 0).initialize(to: features.handle._cTensorHandle)
        address!.advanced(by: 1).initialize(to: labels.handle._cTensorHandle)
    }
    public init(_owning tensorHandles: UnsafePointer<CTensorHandle>?) {
        features = Tensor(handle: TensorHandle(_owning: tensorHandles!.advanced(by: 0).pointee))
        labels = Tensor(handle: TensorHandle(_owning: tensorHandles!.advanced(by: 1).pointee))
    }
    public init<C: RandomAccessCollection>(_handles: C) where C.Element: _AnyTensorHandle {
        fatalError("unimplemented")
    }
}

/// Initialize an `IrisBatch` dataset from a CSV file.
extension Dataset where Element == IrisBatch {
    init(
        contentsOfCSVFile: String, hasHeader: Bool, featureColumns: [Int], labelColumns: [Int]
    ) {
        let np = Python.import("numpy")

        let featuresNp = np.loadtxt(
            contentsOfCSVFile,
            delimiter: ",",
            skiprows: hasHeader ? 1 : 0,
            usecols: featureColumns,
            dtype: Float.numpyScalarTypes.first!)
        guard let featuresTensor = Tensor<Float>(numpy: featuresNp) else {
            // This should never happen, because we construct numpy in such a
            // way that it should be convertible to tensor.
            fatalError("np.loadtxt result can't be converted to Tensor")
        }

        let labelsNp = np.loadtxt(
            contentsOfCSVFile,
            delimiter: ",",
            skiprows: hasHeader ? 1 : 0,
            usecols: labelColumns,
            dtype: Int32.numpyScalarTypes.first!)
        guard let labelsTensor = Tensor<Int32>(numpy: labelsNp) else {
            // This should never happen, because we construct numpy in such a
            // way that it should be convertible to tensor.
            fatalError("np.loadtxt result can't be converted to Tensor")
        }

        self.init(elements: IrisBatch(features: featuresTensor, labels: labelsTensor))
    }
}

/// Sequence doesn't have a non-predicated `first` property, so we define one.
/// TODO: Add this to Swift's stdlib.
extension Sequence where Element == IrisBatch {
    var first: IrisBatch? {
        return first(where: { _ in true })
    }
}
