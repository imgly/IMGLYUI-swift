import SwiftUI

enum DualCameraMode: String, CaseIterable {
  case horizontal
  case vertical
  case disabled
}

extension DualCameraMode {
  var name: LocalizedStringKey {
    switch self {
    case .horizontal:
      return "Horizontal"
    case .vertical:
      return "Vertical"
    case .disabled:
      return "Off"
    }
  }

  var image: Image {
    switch self {
    case .horizontal:
      return Image(systemName: "rectangle.leadinghalf.filled")
    case .vertical:
      return Image(systemName: "rectangle.bottomhalf.filled")
    case .disabled:
      return Image(systemName: "xmark")
    }
  }

  var rect1: CGRect {
    switch self {
    case .horizontal:
      return CGRect(x: 0, y: 0, width: 1080 / 2, height: 1920)
    case .vertical:
      return CGRect(x: 0, y: 0, width: 1080, height: 1920 / 2)
    case .disabled:
      return CGRect(x: 0, y: 0, width: 1080, height: 1920)
    }
  }

  var rect2: CGRect {
    switch self {
    case .horizontal:
      return CGRect(x: 1080 / 2, y: 0, width: 1080 / 2, height: 1920)
    case .vertical:
      return CGRect(x: 0, y: 1920 / 2, width: 1080, height: 1920 / 2)
    case .disabled:
      return CGRect(x: 0, y: 0, width: 1080, height: 1920)
    }
  }
}
