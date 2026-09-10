import Foundation

@_spi(Internal) public enum StrokeStyle: String, MappedEnum, Labelable {
  case solid = "Solid"
  case dashed = "Dashed"
  case dashedRound = "DashedRound"
  case longDashed = "LongDashed"
  case longDashedRound = "LongDashedRound"
  case dotted = "Dotted"

  @_spi(Internal) public var localizationValue: String.LocalizationValue {
    switch self {
    case .solid: "ly_img_editor_sheet_fill_stroke_style_option_solid"
    case .dashed: "ly_img_editor_sheet_fill_stroke_style_option_dashed"
    case .dashedRound: "ly_img_editor_sheet_fill_stroke_style_option_dashed_round"
    case .longDashed: "ly_img_editor_sheet_fill_stroke_style_option_long_dashed"
    case .longDashedRound: "ly_img_editor_sheet_fill_stroke_style_option_long_dashed_round"
    case .dotted: "ly_img_editor_sheet_fill_stroke_style_option_dotted"
    }
  }

  @_spi(Internal) public var imageName: String? { nil }
}
