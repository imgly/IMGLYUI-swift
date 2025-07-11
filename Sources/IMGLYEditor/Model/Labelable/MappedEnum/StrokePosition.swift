import Foundation
@_spi(Internal) import IMGLYCoreUI

enum StrokePosition: String, MappedEnum, Labelable {
  case inside = "Inner"
  case center = "Center"
  case outside = "Outer"

  var localizationValue: String.LocalizationValue {
    switch self {
    case .inside: "ly_img_editor_sheet_fill_stroke_position_option_inside"
    case .center: "ly_img_editor_sheet_fill_stroke_position_option_center"
    case .outside: "ly_img_editor_sheet_fill_stroke_position_option_outside"
    }
  }

  var imageName: String? {
    switch self {
    case .inside: "custom.stroke.position.inside"
    case .center: "custom.stroke.position.center"
    case .outside: "custom.stroke.position.outside"
    }
  }

  var isSystemImage: Bool { false }
}
