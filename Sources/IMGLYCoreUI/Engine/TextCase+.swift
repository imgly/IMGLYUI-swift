import Foundation
import IMGLYEngine

@_spi(Internal) extension TextCase: Labelable {
  @_spi(Internal) public var localizationValue: String.LocalizationValue {
    switch self {
    case .normal: "ly_img_editor_sheet_format_text_letter_case_option_none"
    case .uppercase: "ly_img_editor_sheet_format_text_letter_case_option_uppercase"
    case .lowercase: "ly_img_editor_sheet_format_text_letter_case_option_lowercase"
    case .titlecase: "ly_img_editor_sheet_format_text_letter_case_option_title_case"
    @unknown default: "ly_img_editor_sheet_format_text_letter_case_option_none"
    }
  }

  @_spi(Internal) public var imageName: String? {
    switch self {
    case .normal: "custom.text.case.as.typed"
    case .uppercase: "custom.text.case.upper"
    case .lowercase: "custom.text.case.lower"
    case .titlecase: "custom.text.case.title"
    @unknown default: "custom.text.case.as.typed"
    }
  }

  @_spi(Internal) public var isSystemImage: Bool { false }

  @_spi(Internal) public var isIconEmbeddedInText: Bool { true }
}
