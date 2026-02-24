import AVFoundation

extension AVAssetWriter: IMGLYCompatible {}

@_spi(Internal) public extension IMGLY where Wrapped == AVAssetWriter {
  /// Finish writing with a safe async wrapper.
  ///
  /// This method uses an explicit continuation instead of the compiler-generated
  /// async bridge for `AVAssetWriter.finishWriting()`. The compiler-generated
  /// bridge produces a continuation whose task-context pointer becomes stale when
  /// statically linked with other Swift concurrency users (e.g. expo-image-picker v16+),
  /// causing crashes in `UnsafeContinuation.resume(returning:)`.
  func finishWriting() async {
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      wrapped.finishWriting {
        continuation.resume()
      }
    }
  }
}
