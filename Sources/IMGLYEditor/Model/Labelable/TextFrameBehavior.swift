import Foundation
@_spi(Internal) import IMGLYCoreUI

enum TextFrameBehavior: Labelable, CaseIterable {
  case auto, autoHeight, fixed

  var description: String {
    switch self {
    case .auto: "Auto Size"
    case .autoHeight: "Auto Height"
    case .fixed: "Fixed Size"
    }
  }

  var imageName: String? {
    switch self {
    case .auto: "custom.text.auto.size"
    case .autoHeight: "custom.text.auto.height"
    case .fixed: "custom.text.fixed.size"
    }
  }

  var isSystemImage: Bool { false }
}
