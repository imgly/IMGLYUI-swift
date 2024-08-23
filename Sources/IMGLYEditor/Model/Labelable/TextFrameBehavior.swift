import Foundation
@_spi(Internal) import IMGLYCoreUI

enum TextFrameBehavior: Labelable, CaseIterable {
  case auto
  case autoHeight
  case fixed

  var imageName: String? { nil }

  var description: String {
    switch self {
    case .auto: "Auto Size"
    case .autoHeight: "Auto Height"
    case .fixed: "Fixed Size"
    }
  }
}
