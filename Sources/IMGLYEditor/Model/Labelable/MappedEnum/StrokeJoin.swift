import Foundation
@_spi(Internal) import IMGLYCoreUI

enum StrokeJoin: String, MappedEnum {
  case miter = "Miter"
  case bevel = "Bevel"
  case round = "Round"

  var description: String {
    switch self {
    case .miter: return "Miter"
    case .bevel: return "Bevel"
    case .round: return "Round"
    }
  }

  var imageName: String? {
    switch self {
    case .miter: return "join_miter"
    case .bevel: return "join_bevel"
    case .round: return "join_round"
    }
  }

  var isSystemImage: Bool { false }
}
