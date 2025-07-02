@_spi(Internal) import IMGLYCoreUI

enum ContentFillMode: String, MappedEnum {
  case Cover
  case Crop
  case Contain

  var imageName: String? {
    switch self {
    case .Cover:
      "custom.fillmode.crop"
    case .Crop:
      "custom.fillmode.cover"
    case .Contain:
      "custom.fillmode.fit"
    }
  }

  var description: String {
    switch self {
    case .Crop:
      "Crop"
    case .Cover:
      "Cover"
    case .Contain:
      "Fit"
    }
  }

  var isSystemImage: Bool { false }
}
