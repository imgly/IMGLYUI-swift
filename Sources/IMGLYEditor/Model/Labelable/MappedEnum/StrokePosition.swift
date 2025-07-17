import Foundation
@_spi(Internal) import IMGLYCoreUI

enum StrokePosition: String, MappedEnum {
  case inside = "Inner"
  case center = "Center"
  case outside = "Outer"

  var description: String {
    switch self {
    case .inside: "Inside"
    case .center: "Center"
    case .outside: "Outside"
    }
  }

  var imageName: String? {
    switch self {
    case .inside: "custom.stroke.position.inside"
    case .center: "custom.stroke.position.center"
    case .outside: "custom.stroke.position.outside"
    }
  }

  var isSystemImage: Bool { false }
}
