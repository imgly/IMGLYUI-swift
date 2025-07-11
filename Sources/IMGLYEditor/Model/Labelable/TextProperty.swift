import Foundation
@_spi(Internal) import IMGLYCoreUI

enum TextProperty: Labelable, IdentifiableByHash, CaseIterable {
  case inactive, bold, italic

  var localizationValue: String.LocalizationValue {
    switch self {
    case .inactive: "Inactive"
    case .bold: "ly_img_editor_sheet_format_text_button_bold"
    case .italic: "ly_img_editor_sheet_format_text_button_italic"
    }
  }

  var imageName: String? {
    switch self {
    case .inactive: nil
    case .bold: "bold"
    case .italic: "italic"
    }
  }
}
