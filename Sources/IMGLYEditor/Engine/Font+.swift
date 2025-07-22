import Foundation
import IMGLYEngine
@_spi(Internal) import IMGLYCoreUI

extension Font {
  private enum SubFamily: String, Localizable {
    case black = "Black"
    case blackItalic = "Black Italic"
    case bold = "Bold"
    case boldItalic = "Bold Italic"
    case extraBold = "ExtraBold"
    case extraBoldItalic = "ExtraBold Italic"
    case extraLight = "ExtraLight"
    case extraLight_italic = "ExtraLight Italic"
    case italic = "Italic"
    case light = "Light"
    case lightItalic = "Light Italic"
    case medium = "Medium"
    case mediumItalic = "Medium Italic"
    case regular = "Regular"
    case semiBold = "SemiBold"
    case semiBoldItalic = "SemiBold Italic"
    case thin = "Thin"
    case thinItalic = "Thin Italic"

    var localizationValue: String.LocalizationValue {
      switch self {
      case .black: "ly_img_editor_sheet_format_text_font_subfamily_black"
      case .blackItalic: "ly_img_editor_sheet_format_text_font_subfamily_black_italic"
      case .bold: "ly_img_editor_sheet_format_text_font_subfamily_bold"
      case .boldItalic: "ly_img_editor_sheet_format_text_font_subfamily_bold_italic"
      case .extraBold: "ly_img_editor_sheet_format_text_font_subfamily_extrabold"
      case .extraBoldItalic: "ly_img_editor_sheet_format_text_font_subfamily_extrabold_italic"
      case .extraLight: "ly_img_editor_sheet_format_text_font_subfamily_extralight"
      case .extraLight_italic: "ly_img_editor_sheet_format_text_font_subfamily_extralight_italic"
      case .italic: "ly_img_editor_sheet_format_text_font_subfamily_italic"
      case .light: "ly_img_editor_sheet_format_text_font_subfamily_light"
      case .lightItalic: "ly_img_editor_sheet_format_text_font_subfamily_light_italic"
      case .medium: "ly_img_editor_sheet_format_text_font_subfamily_medium"
      case .mediumItalic: "ly_img_editor_sheet_format_text_font_subfamily_medium_italic"
      case .regular: "ly_img_editor_sheet_format_text_font_subfamily_regular"
      case .semiBold: "ly_img_editor_sheet_format_text_font_subfamily_semibold"
      case .semiBoldItalic: "ly_img_editor_sheet_format_text_font_subfamily_semibold_italic"
      case .thin: "ly_img_editor_sheet_format_text_font_subfamily_thin"
      case .thinItalic: "ly_img_editor_sheet_format_text_font_subfamily_thin_italic"
      }
    }
  }

  var localizedSubFamiliy: LocalizedStringResource {
    if let subFamily = SubFamily(rawValue: subFamily) {
      subFamily.localizedStringResource
    } else {
      "\(subFamily)"
    }
  }
}
