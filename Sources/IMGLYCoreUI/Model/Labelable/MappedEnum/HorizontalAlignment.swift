import Foundation

@_spi(Internal) public enum HorizontalAlignment: String, MappedEnum, Labelable {
  case left = "Left"
  case center = "Center"
  case right = "Right"
  case auto = "Auto"

  @_spi(Internal) public var localizationValue: String.LocalizationValue {
    switch self {
    case .left: "ly_img_editor_sheet_format_text_alignment_horizontal_option_left"
    case .center: "ly_img_editor_sheet_format_text_alignment_horizontal_option_center"
    case .right: "ly_img_editor_sheet_format_text_alignment_horizontal_option_right"
    case .auto: "ly_img_editor_sheet_format_text_alignment_horizontal_option_auto"
    }
  }

  @_spi(Internal) public var imageName: String? {
    switch self {
    case .left: "text.alignleft"
    case .center: "text.aligncenter"
    case .right: "text.alignright"
    case .auto: "text.alignleft" // Auto uses left-align icon as fallback
    }
  }
}
