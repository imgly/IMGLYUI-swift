import Foundation
@_spi(Internal) import IMGLYCore
import IMGLYEngine

@_spi(Internal) public enum ColorFillType: String, MappedEnum, Labelable {
  case solid = "//ly.img.ubq/fill/color"
  case gradient = "//ly.img.ubq/fill/gradient/linear"
  case none

  @_spi(Internal) public var localizationValue: String.LocalizationValue {
    switch self {
    case .solid: "ly_img_editor_sheet_fill_stroke_type_option_solid"
    case .gradient: "ly_img_editor_sheet_fill_stroke_type_option_gradient_linear"
    case .none: "ly_img_editor_sheet_fill_stroke_type_option_none"
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
