import Foundation
@_spi(Internal) import IMGLYCoreUI

enum StrokeJoin: String, MappedEnum {
  case miter = "Miter"
  case bevel = "Bevel"
  case round = "Round"

  var description: String {
    switch self {
    case .miter: "Miter"
    case .bevel: "Bevel"
    case .round: "Round"
    }
  }

  var imageName: String? {
    switch self {
    case .miter: "custom.stroke.join.miter"
    case .bevel: "custom.stroke.join.bevel"
    case .round: "custom.stroke.join.round"
    }
  }

  var isSystemImage: Bool { false }
}
