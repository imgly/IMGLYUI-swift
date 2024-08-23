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
    case .miter: "join_miter"
    case .bevel: "join_bevel"
    case .round: "join_round"
    }
  }

  var isSystemImage: Bool { false }
}
