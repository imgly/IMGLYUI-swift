import SwiftUI
@_spi(Internal) import IMGLYCoreUI

enum SizeLetter: String, Localizable {
  case small = "Small"
  case medium = "Medium"
  case large = "Large"

  var description: String { rawValue }
}

extension SizeLetter {
  init(_ fontSize: Float) {
    switch fontSize {
    case ...Self.small.fontSize: self = .small
    case ...Self.medium.fontSize: self = .medium
    default: self = .large
    }
  }

  var fontSize: Float {
    switch self {
    case .small: 14
    case .medium: 18
    case .large: 22
    }
  }

  var sizeLetter: String {
    switch self {
    case .small: "S"
    case .medium: "M"
    case .large: "L"
    }
  }

  @ViewBuilder var icon: some View {
    Text(sizeLetter)
  }
}
