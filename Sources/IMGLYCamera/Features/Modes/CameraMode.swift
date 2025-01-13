import CoreMedia
import SwiftUI

/// Enumerates the different camera modes.
public enum CameraMode: Equatable, Sendable {
  /// The standard, main, camera.
  case standard
  /// Records with two cameras at once into a given layout.
  case dualCamera(CameraLayoutMode = .vertical)
  /// Records with one camera while playing a video.
  case reaction(CameraLayoutMode = .vertical, video: URL, positionsSwapped: Bool = false)

  var rect1: CGRect {
    switch layoutMode {
    case .vertical: arePositionsSwapped ? bottomRect : topRect
    case .horizontal: arePositionsSwapped ? rightRect : leftRect
    case .none: fullScreen
    }
  }

  var rect2: CGRect? {
    switch layoutMode {
    case .vertical: !arePositionsSwapped ? bottomRect : topRect
    case .horizontal: !arePositionsSwapped ? rightRect : leftRect
    case .none: nil
    }
  }

  var layoutMode: CameraLayoutMode? {
    switch self {
    case let .dualCamera(layoutMode), let .reaction(layoutMode, _, _):
      layoutMode
    case .standard:
      nil
    }
  }

  var isMultiCamera: Bool {
    switch self {
    case .dualCamera: true
    default: false
    }
  }

  var isReaction: Bool {
    switch self {
    case .reaction: true
    default: false
    }
  }

  var supportsFlash: Bool {
    switch self {
    case .dualCamera: false
    default: true
    }
  }

  var arePositionsSwapped: Bool {
    switch self {
    case let .reaction(_, _, positionsSwapped):
      positionsSwapped
    default:
      false
    }
  }

  /// When recording for the main recording is the second rect.
  /// This is used in the CaptureService to get the video to the right position.
  var firstRecordingRect: CGRect {
    switch self {
    case .reaction: rect2 ?? .zero
    default: rect1
    }
  }

  func reactionVideo(duration: CMTime) -> Recording? {
    guard case let .reaction(_, url, _) = self else {
      return nil
    }
    return Recording(videos: [.init(url: url, rect: rect1)], duration: duration)
  }
}

private extension CameraMode {
  var fullScreen: CGRect { CGRect(x: 0, y: 0, width: 1080, height: 1920) }

  var topRect: CGRect {
    fullScreen.divided(atDistance: fullScreen.midY, from: .minYEdge).slice
  }

  var bottomRect: CGRect {
    fullScreen.divided(atDistance: fullScreen.midY, from: .minYEdge).remainder
  }

  var leftRect: CGRect {
    fullScreen.divided(atDistance: fullScreen.midX, from: .minXEdge).slice
  }

  var rightRect: CGRect {
    fullScreen.divided(atDistance: fullScreen.midX, from: .minXEdge).remainder
  }
}
