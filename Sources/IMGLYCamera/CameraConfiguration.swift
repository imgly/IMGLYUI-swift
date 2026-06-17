import CoreMedia
@_spi(Internal) import IMGLYCore
import SwiftUI

/// Camera configuration options.
public struct CameraConfiguration {
  /// Creates a camera configuration.
  /// - Parameters:
  ///   - recordingColor: The color of the record button while recording, and all the other recording indicators.
  ///   - highlightColor: The color used to highlight the camera buttons on tap.
  ///   - maxTotalDuration: The target duration for the recording.
  ///   - allowExceedingMaxDuration: Adjusts the segments visualization to use the max duration, but does not enforce
  ///     the limit.
  ///   - allowModeSwitching: Set to `false` to lock the camera into the initial mode.
  ///   - captureType: The kind of media the camera captures.
  ///   - captureCount: How many captures the session produces.
  ///   - photoClipDuration: The duration stamped on each captured photo.
  ///   - showsPhotoPreview: Whether to show a full-screen preview after each photo capture.
  ///     When `false`, captured photos are committed immediately.
  public init(
    recordingColor: Color = .pink,
    highlightColor: Color = .pink,
    maxTotalDuration: TimeInterval = .infinity,
    allowExceedingMaxDuration: Bool = false,
    allowModeSwitching: Bool = true,
    captureType: CaptureType = .video,
    captureCount: CaptureCount = .multi,
    photoClipDuration: TimeInterval = 5,
    showsPhotoPreview: Bool = true,
  ) {
    self.recordingColor = recordingColor
    self.highlightColor = highlightColor
    self.allowExceedingMaxDuration = allowExceedingMaxDuration
    self.maxTotalDuration = maxTotalDuration == .infinity ? .positiveInfinity : CMTime(seconds: maxTotalDuration)
    self.allowModeSwitching = allowModeSwitching
    self.captureType = captureType
    self.captureCount = captureCount
    self.photoClipDuration = CMTime(seconds: photoClipDuration)
    self.showsPhotoPreview = showsPhotoPreview
  }

  /// The color of the record button while recording, and all the other recording indicators.
  public let recordingColor: Color
  /// The color used to highlight the camera buttons on tap.
  public let highlightColor: Color
  /// Adjusts the segments visualization to use the max duration, but does not enforce the limit.
  public let allowExceedingMaxDuration: Bool
  /// The target duration for the recording.
  public let maxTotalDuration: CMTime
  /// The dimensions of the recorded video.
  public let videoSize = CameraConfiguration.defaultVideoSize

  /// The default frame size used by camera-produced video scenes.
  public static let defaultVideoSize = CGSize(width: 1080, height: 1920)
  /// Set to `false` to lock the camera into the initial mode.
  public let allowModeSwitching: Bool
  /// The kind of media the camera captures.
  public let captureType: CaptureType
  /// How many captures the session produces.
  public let captureCount: CaptureCount
  /// The duration stamped on each captured photo.
  public let photoClipDuration: CMTime
  /// Whether to show a full-screen preview after each photo capture.
  public let showsPhotoPreview: Bool
}

extension CameraConfiguration {
  /// Returns a copy of this configuration with `captureType` forced to `.video`. Used by the
  /// deprecated initializer whose `Result<[Recording], CameraError>` callback can't carry photos.
  func forcingVideoCaptureType() -> CameraConfiguration {
    CameraConfiguration(
      recordingColor: recordingColor,
      highlightColor: highlightColor,
      maxTotalDuration: maxTotalDuration == .positiveInfinity ? .infinity : maxTotalDuration.seconds,
      allowExceedingMaxDuration: allowExceedingMaxDuration,
      allowModeSwitching: allowModeSwitching,
      captureType: .video,
      captureCount: captureCount,
      photoClipDuration: photoClipDuration.seconds,
      showsPhotoPreview: showsPhotoPreview,
    )
  }
}
