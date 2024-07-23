import SwiftUI

enum CameraMode: Equatable {
  case standard
  case dualCamera(CameraLayoutMode = .vertical)
  case reactions(CameraLayoutMode = .vertical, video: URL)

  var rect1: CGRect {
    switch layoutMode {
    case .horizontal:
      return CGRect(x: 0, y: 0, width: 1080 / 2, height: 1920)
    case .vertical:
      return CGRect(x: 0, y: 0, width: 1080, height: 1920 / 2)
    case .none:
      return CGRect(x: 0, y: 0, width: 1080, height: 1920)
    }
  }

  var rect2: CGRect? {
    switch layoutMode {
    case .horizontal:
      return CGRect(x: 1080 / 2, y: 0, width: 1080 / 2, height: 1920)
    case .vertical:
      return CGRect(x: 0, y: 1920 / 2, width: 1080, height: 1920 / 2)
    case .none:
      return nil
    }
  }

  var layoutMode: CameraLayoutMode? {
    switch self {
    case let .dualCamera(layoutMode), let .reactions(layoutMode, _):
      return layoutMode
    case .standard:
      return nil
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
