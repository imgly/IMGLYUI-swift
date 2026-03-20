import Foundation
import IMGLYEngine

@_spi(Internal) extension ListStyle: Labelable {
  @_spi(Internal) public var localizationValue: String.LocalizationValue {
    switch self {
    case .none: "ly_img_editor_sheet_format_text_list_style_option_none"
    case .unordered: "ly_img_editor_sheet_format_text_list_style_option_unordered"
    case .ordered: "ly_img_editor_sheet_format_text_list_style_option_ordered"
    @unknown default: "ly_img_editor_sheet_format_text_list_style_option_none"
    }
  }

  @_spi(Internal) public var imageName: String? {
    switch self {
    case .none: "minus"
    case .unordered: "list.bullet"
    case .ordered: "list.number"
    @unknown default: "minus"
    }
  }
}
