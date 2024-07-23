import SwiftUI

enum CameraLayoutMode: String, CaseIterable, Equatable {
  case horizontal
  case vertical
}

extension CameraLayoutMode {
  var name: LocalizedStringKey {
    switch self {
    case .horizontal:
      return "Horizontal"
    case .vertical:
      return "Vertical"
    }
  }

  var image: Image {
    switch self {
    case .horizontal:
      return Image(systemName: "rectangle.leadinghalf.filled")
    case .vertical:
      return Image(systemName: "rectangle.bottomhalf.filled")
    }
  }
}
