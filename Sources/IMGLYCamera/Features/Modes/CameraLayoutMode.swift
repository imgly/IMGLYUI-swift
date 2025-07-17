import SwiftUI

/// Determines the layout of the camera in case of dual camera or reactions.
public enum CameraLayoutMode: String, CaseIterable, Equatable, Sendable {
  /// Displays two video feeds, one on top of the other.
  case vertical
  /// Displays two video feeds next to each other.
  case horizontal
}

extension CameraLayoutMode {
  var name: LocalizedStringKey {
    switch self {
    case .horizontal:
      "Horizontal"
    case .vertical:
      "Vertical"
    }
  }

  var image: Image {
    switch self {
    case .horizontal:
      Image(systemName: "rectangle.leadinghalf.filled")
    case .vertical:
      Image(systemName: "rectangle.bottomhalf.filled")
    }
  }
}
