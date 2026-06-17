import CoreMedia
import Foundation

/// A single item produced by the camera.
public enum Capture: Equatable, Sendable {
  /// A still photo. `Photo.images` is 1-element in single-camera mode and 2-element in dual-camera mode.
  case photo(Photo)
  /// A video clip.
  case video(Recording)
}

extension Capture {
  /// File URLs backing this capture (one or two per photo, one or two per video).
  var fileURLs: [URL] {
    switch self {
    case let .photo(photo):
      photo.images.map(\.url)
    case let .video(recording):
      recording.videos.map(\.url)
    }
  }

  /// Duration this capture contributes to a multi-capture stack.
  var duration: CMTime {
    switch self {
    case let .photo(photo):
      photo.duration
    case let .video(recording):
      recording.duration
    }
  }
}
