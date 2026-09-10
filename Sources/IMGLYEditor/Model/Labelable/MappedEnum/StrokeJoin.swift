import Foundation
@_spi(Internal) import IMGLYCoreUI

enum StrokeJoin: String, MappedEnum, Labelable {
  case miter = "Miter"
  case bevel = "Bevel"
  case round = "Round"

  var localizationValue: String.LocalizationValue {
    switch self {
    case .miter: "ly_img_editor_sheet_fill_stroke_join_option_miter"
    case .bevel: "ly_img_editor_sheet_fill_stroke_join_option_bevel"
    case .round: "ly_img_editor_sheet_fill_stroke_join_option_round"
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
