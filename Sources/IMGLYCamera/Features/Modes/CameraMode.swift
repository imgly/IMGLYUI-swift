import SwiftUI

/// Enumerates the different camera modes.
@_spi(Internal) public enum CameraMode: Equatable, Sendable {
  /// The standard, main, camera.
  case standard
  /// Records with two cameras at once into a given layout.
  case dualCamera(CameraLayoutMode = .vertical)
  /// Records with one camera while playing a video.
  case reactions(CameraLayoutMode = .vertical, video: URL)

  var rect1: CGRect {
    switch layoutMode {
    case .horizontal:
      CGRect(x: 0, y: 0, width: 1080 / 2, height: 1920)
    case .vertical:
      CGRect(x: 0, y: 0, width: 1080, height: 1920 / 2)
    case .none:
      CGRect(x: 0, y: 0, width: 1080, height: 1920)
    }
  }

  var rect2: CGRect? {
    switch layoutMode {
    case .horizontal:
      CGRect(x: 1080 / 2, y: 0, width: 1080 / 2, height: 1920)
    case .vertical:
      CGRect(x: 0, y: 1920 / 2, width: 1080, height: 1920 / 2)
    case .none:
      nil
    }
  }

  var layoutMode: CameraLayoutMode? {
    switch self {
    case let .dualCamera(layoutMode), let .reactions(layoutMode, _):
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

  var supportsFlash: Bool {
    switch self {
    case .dualCamera: false
    default: true
    }
  }
}
