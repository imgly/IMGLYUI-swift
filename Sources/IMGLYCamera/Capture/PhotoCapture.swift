@preconcurrency import AVFoundation
import Foundation

/// Bridges `AVCapturePhotoCaptureDelegate` to async/await, writing the still to a JPEG file and returning its URL.
final class PhotoCapture: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
  private var continuation: CheckedContinuation<URL, Swift.Error>?

  func capture(
    with output: AVCapturePhotoOutput,
    flashMode: AVCaptureDevice.FlashMode,
  ) async throws -> URL {
    try await withCheckedThrowingContinuation { continuation in
      self.continuation = continuation
      output.capturePhoto(with: makeSettings(for: output, flashMode: flashMode), delegate: self)
    }
  }

  private func makeSettings(
    for output: AVCapturePhotoOutput,
    flashMode: AVCaptureDevice.FlashMode,
  ) -> AVCapturePhotoSettings {
    // Engine's image-scene loader only accepts JPEG.
    let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
    if output.supportedFlashModes.contains(flashMode) {
      settings.flashMode = flashMode
    }
    return settings
  }

  func photoOutput(
    _: AVCapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: Swift.Error?,
  ) {
    let continuation = continuation
    self.continuation = nil

    if let error {
      continuation?.resume(throwing: error)
      return
    }
    guard let data = photo.fileDataRepresentation() else {
      continuation?.resume(throwing: PhotoCaptureError.noFileData)
      return
    }
    let url = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("jpg")
    do {
      try data.write(to: url)
      continuation?.resume(returning: url)
    } catch {
      continuation?.resume(throwing: error)
    }
  }
}

private enum PhotoCaptureError: Swift.Error {
  case noFileData
}
