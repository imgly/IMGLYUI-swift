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
  /// the limit.
  public init(
    recordingColor: Color = .pink,
    highlightColor: Color = .pink,
    maxTotalDuration: TimeInterval = .infinity,
    allowExceedingMaxDuration: Bool = false
  ) {
    self.recordingColor = recordingColor
    self.highlightColor = highlightColor
    self.allowExceedingMaxDuration = allowExceedingMaxDuration
    self.maxTotalDuration = maxTotalDuration == .infinity ? .positiveInfinity : CMTime(seconds: maxTotalDuration)
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
  public let videoSize = CGSize(width: 1080, height: 1920)
}
