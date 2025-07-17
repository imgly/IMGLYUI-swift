import Foundation
@_spi(Internal) import IMGLYCoreUI

enum VerticalAlignment: String, MappedEnum {
  case top = "Top"
  case center = "Center"
  case bottom = "Bottom"

  var description: String {
    switch self {
    case .top: "Align Top"
    case .center: "Align Vertical Center"
    case .bottom: "Align Bottom"
    }
  }

  var imageName: String? {
    switch self {
    case .top: "arrow.up.to.line"
    case .center: "arrow.down.and.line.horizontal.and.arrow.up"
    case .bottom: "arrow.down.to.line"
    }
  }
}
