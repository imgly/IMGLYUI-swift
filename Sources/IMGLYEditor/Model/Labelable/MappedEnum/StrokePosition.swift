import Foundation
@_spi(Internal) import IMGLYCoreUI

enum StrokePosition: String, MappedEnum {
  case inside = "Inner"
  case center = "Center"
  case outside = "Outer"

  var description: String {
    switch self {
    case .inside: return "Inside"
    case .center: return "Center"
    case .outside: return "Outside"
    }
  }

  var imageName: String? {
    switch self {
    case .inside: return "stroke_position_inside"
    case .center: return "stroke_position_center"
    case .outside: return "stroke_position_outside"
    }
  }

  var isSystemImage: Bool { false }
}
