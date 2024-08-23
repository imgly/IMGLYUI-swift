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
    case .inside: "stroke_position_inside"
    case .center: "stroke_position_center"
    case .outside: "stroke_position_outside"
    }
  }

  var isSystemImage: Bool { false }
}
