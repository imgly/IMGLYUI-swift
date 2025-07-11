import Foundation
@_spi(Internal) import IMGLYCoreUI

enum VerticalAlignment: String, MappedEnum, Labelable {
  case top = "Top"
  case center = "Center"
  case bottom = "Bottom"

  var localizationValue: String.LocalizationValue {
    switch self {
    case .top: "ly_img_editor_sheet_format_text_alignment_vertical_option_top"
    case .center: "ly_img_editor_sheet_format_text_alignment_vertical_option_center"
    case .bottom: "ly_img_editor_sheet_format_text_alignment_vertical_option_bottom"
    }
  }

  var imageName: String? {
    switch self {
    case .top: "arrow.up.to.line"
    case .center: "arrow.down.and.line.horizontal.and.arrow.up"
    case .bottom: "arrow.down.to.line"
    }
  }
}
