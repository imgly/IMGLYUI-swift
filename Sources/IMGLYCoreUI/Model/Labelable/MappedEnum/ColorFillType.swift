import Foundation
@_spi(Internal) import IMGLYCore
import IMGLYEngine

@_spi(Internal) public enum ColorFillType: String, MappedEnum, Labelable {
  case solid = "//ly.img.ubq/fill/color"
  case gradient = "//ly.img.ubq/fill/gradient/linear"
  case radialGradient = "//ly.img.ubq/fill/gradient/radial"
  case conicalGradient = "//ly.img.ubq/fill/gradient/conical"
  case none

  /// The types that the fill and stroke sheet offers. The editor shows a radial or conical gradient from the API or
  /// another editor, but does not create one.
  @_spi(Internal) public static var offered: [ColorFillType] {
    [.solid, .gradient, .none]
  }

  /// Whether the fill is a gradient, which keeps its colors in `fill/gradient/colors`.
  @_spi(Internal) public var isGradient: Bool {
    self == .gradient || self == .radialGradient || self == .conicalGradient
  }

  @_spi(Internal) public var localizationValue: String.LocalizationValue {
    switch self {
    case .solid: "ly_img_editor_sheet_fill_stroke_type_option_solid"
    case .gradient: "ly_img_editor_sheet_fill_stroke_type_option_gradient_linear"
    case .radialGradient: "ly_img_editor_sheet_fill_stroke_type_option_gradient_radial"
    case .conicalGradient: "ly_img_editor_sheet_fill_stroke_type_option_gradient_conical"
    case .none: "ly_img_editor_sheet_fill_stroke_type_option_none"
    }
  }

  @_spi(Internal) public var imageName: String? {
    nil
  }

  func fillType() throws -> FillType {
    guard let fillType = FillType(rawValue: rawValue) else {
      throw Error(errorDescription: "Unimplemented type mapping from raw value '\(rawValue)' to FillType.")
    }
    return fillType
  }
}
