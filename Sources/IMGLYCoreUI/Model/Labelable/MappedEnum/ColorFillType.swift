import Foundation
@_spi(Internal) import IMGLYCore
import IMGLYEngine

@_spi(Internal) public enum ColorFillType: String, MappedEnum {
  case solid = "//ly.img.ubq/fill/color"
  case gradient = "//ly.img.ubq/fill/gradient/linear"
  case none

  @_spi(Internal) public var description: String {
    switch self {
    case .solid: return "Solid"
    case .gradient: return "Gradient"
    case .none: return "None"
    }
  }

  @_spi(Internal) public var imageName: String? { nil }

  func fillType() throws -> FillType {
    guard let fillType = FillType(rawValue: rawValue) else {
      throw Error(errorDescription: "Unimplemented type mapping from raw value '\(rawValue)' to FillType.")
    }
    return fillType
  }
}
