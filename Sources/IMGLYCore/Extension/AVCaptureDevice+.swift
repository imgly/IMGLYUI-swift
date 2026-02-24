import AVFoundation

extension AVCaptureDevice: IMGLYCompatible {}

@_spi(Internal) public extension IMGLY where Wrapped == AVCaptureDevice {
  /// Request access to capture devices with a safe async wrapper.
  ///
  /// This method uses an explicit continuation instead of the compiler-generated
  /// async bridge for `AVCaptureDevice.requestAccess(for:)`. The compiler-generated
  /// bridge produces a continuation whose task-context pointer becomes stale when
  /// statically linked with other Swift concurrency users (e.g. expo-image-picker v16+),
  /// causing crashes in `UnsafeContinuation.resume(returning:)`.
  ///
  /// - Parameter mediaType: The media type (video or audio) to request access for.
  /// - Returns: `true` if access was granted, `false` otherwise.
  static func requestAccess(for mediaType: AVMediaType) async -> Bool {
    await withCheckedContinuation { continuation in
      AVCaptureDevice.requestAccess(for: mediaType) { granted in
        continuation.resume(returning: granted)
      }
    }
  }
}
