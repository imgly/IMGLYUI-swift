import Foundation
@_spi(Internal) import IMGLYCoreUI

enum VerticalAlignment: String, MappedEnum {
  case top = "Top"
  case center = "Center"
  case bottom = "Bottom"

  var description: String {
    switch self {
    case .top: return "Align Top"
    case .center: return "Align Vertical Center"
    case .bottom: return "Align Bottom"
    }
  }

  var imageName: String? {
    switch self {
    case .top: return "arrow.up.to.line"
    case .center: return "arrow.down.and.line.horizontal.and.arrow.up"
    case .bottom: return "arrow.down.to.line"
    }
  }
}
