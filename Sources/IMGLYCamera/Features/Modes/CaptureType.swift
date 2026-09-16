import Foundation

/// Enumerates the kinds of media the camera can capture.
public enum CaptureType: Equatable, Sendable {
  /// Captures still photos only.
  case photo
  /// Records videos only.
  case video
  /// Switches between photo and video via an in-camera toggle.
  case mixed
}
