import Foundation
import IMGLYEngine

@_spi(Internal) extension ScriptStyle: Labelable {
  @_spi(Internal) public var localizationValue: String.LocalizationValue {
    switch self {
    case .normal: "ly_img_editor_sheet_format_text_script_style_option_normal"
    case .superscript: "ly_img_editor_sheet_format_text_script_style_option_superscript"
    case .subscript: "ly_img_editor_sheet_format_text_script_style_option_subscript"
    @unknown default: "ly_img_editor_sheet_format_text_script_style_option_normal"
    }
  }

  @_spi(Internal) public var imageName: String? {
    switch self {
    case .normal: "minus"
    case .superscript: "textformat.superscript"
    case .subscript: "textformat.subscript"
    @unknown default: "minus"
    }
  }
}
