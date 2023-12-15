import Foundation
@_spi(Internal) import IMGLYCoreUI

enum SizeMode: String, MappedEnum {
  case absolute = "Absolute"
  case percent = "Percent"
  case auto = "Auto"

  var description: String {
    switch self {
    case .absolute: return "Fixed Size"
    case .percent: return "Percent"
    case .auto: return "Auto Height"
    }
  }

  var imageName: String? {
    switch self {
    case .absolute: return "custom_fixed_size"
    case .percent: return nil
    case .auto: return "custom_auto_height"
    }
  }

  var isSystemImage: Bool { false }
}
