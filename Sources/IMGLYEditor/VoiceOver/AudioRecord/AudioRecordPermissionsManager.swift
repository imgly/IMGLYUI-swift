import AVFoundation

/// Enum to represent the possible states of audio recording permissions.
enum AudioRecordPermission {
  case granted
  case denied
}

/// Manages checking and requesting the user's permission for audio recording.
enum AudioRecordPermissionsManager {
  /// Checks the authorization status for audio recording and requests permission if not determined.
  /// - Returns: The `AudioRecordPermission` depending on the user's choice or existing status.
  static func checkAudioRecordingPermission() async -> AudioRecordPermission {
    let status = AVCaptureDevice.authorizationStatus(for: .audio)

    switch status {
    case .authorized:
      return .granted
    case .notDetermined:
      return await AVCaptureDevice.requestAccess(for: .audio) == true ? .granted : .denied
    case .denied, .restricted:
      return .denied
    @unknown default:
      // Log an unexpected case which might be introduced in future iOS versions.
      print("Encountered an unknown authorization status for audio recording.")
      return .denied
    }
  }
}
