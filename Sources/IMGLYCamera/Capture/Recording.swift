import CoreMedia
import Foundation

/// A camera recording.
public struct Recording: Equatable, Sendable {
  /// A video recording.
  public struct Video: Equatable, Sendable {
    /// The URL of the recorded video file.
    public let url: URL
    /// The position and size of the video.
    public let rect: CGRect
  }

  /// Contains one or two `Video`s, for single camera mode or video that was reacted to and dual camera mode
  /// respectively.
  public let videos: [Video]

  /// The duration of the recording.
  public let duration: CMTime
}
