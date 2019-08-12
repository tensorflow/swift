public func avgPool1D(
    _ out: inout [Float], _ input: [Float], _ windowSize: Int, _ windowStride: Int,
    _ outScale: Float
) {
    let n = input.count
    let outSize = (n - windowSize) / windowStride + 1
    let outStart = threadIndex()
    let outStride = threadCount()
    for outIndex in stride(from: outStart, to: outSize, by: outStride) {
        out[outIndex] = 0.0
        let beginWindow = outIndex * windowStride
        let endWindow = outIndex * windowStride + windowSize
        for inputIndex in beginWindow..<endWindow {
            out[outIndex] += input[inputIndex]
        }
        out[outIndex] /= Float(windowSize)
        out[outIndex] *= outScale
    }
}

public func threadIndex() -> Int {
    return 0
}

public func threadCount() -> Int {
    return 1
}
