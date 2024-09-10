import Foundation

/// The error returned from the camera when it’s dismissed.
public enum CameraError: Error {
  case cancelled
  case permissionsMissing
}

extension CameraError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .cancelled:
      return "The user has cancelled the camera."
    case .permissionsMissing:
      return "The user has denied camera or microphone access."
    }
  }
}

/// The internal error state to be displayed the error screen.
enum CameraCaptureError: Error, Equatable {
  case captureError(String)
  case unknownCaptureError
  case imglyEngineError(String)
  case permissionsMissing
  case noCameraAvailable

  // These mirror the errors in AVCaptureSession.InterruptionReason
  case videoDeviceNotAvailableInBackground
  case audioDeviceInUseByAnotherClient
  case videoDeviceInUseByAnotherClient
  case videoDeviceNotAvailableWithMultipleForegroundApps
  case videoDeviceNotAvailableDueToSystemPressure
}

extension CameraCaptureError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case let .captureError(localizedDescription):
      return localizedDescription
    case .unknownCaptureError:
      return "Camera recording is not working properly."
    case let .imglyEngineError(localizedDescription):
      return localizedDescription
    case .permissionsMissing:
      return "Please allow using your camera and microphone."
    case .noCameraAvailable:
      return "No camera could be found."
    case .videoDeviceNotAvailableInBackground:
      return "The app was sent to the background while using a camera."
    case .audioDeviceInUseByAnotherClient:
      return "The audio hardware is temporarily not available."
    case .videoDeviceInUseByAnotherClient:
      return "The video device is temporarily not available."
    case .videoDeviceNotAvailableWithMultipleForegroundApps:
      return "The video device doesn’t work in Slide Over Split View, or Picture in Picture mode."
    case .videoDeviceNotAvailableDueToSystemPressure:
      return "The camera ran too hot. Please wait and try again."
    }
  }
}

internal struct InternalCameraError: LocalizedError {
  let errorDescription: String?

  init(errorDescription: String?) {
    self.errorDescription = errorDescription
  }
}
