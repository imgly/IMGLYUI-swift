import Foundation
@_spi(Internal) import IMGLYCoreUI

enum TextFrameBehavior: Labelable, CaseIterable {
  case auto, autoHeight, fixed

  var localizationValue: String.LocalizationValue {
    switch self {
    case .auto: "ly_img_editor_sheet_format_text_frame_behavior_option_auto_size"
    case .autoHeight: "ly_img_editor_sheet_format_text_frame_behavior_option_auto_height"
    case .fixed: "ly_img_editor_sheet_format_text_frame_behavior_option_fixed_size"
    }
  }

  var imageName: String? {
    switch self {
    case .auto: "custom.text.auto.size"
    case .autoHeight: "custom.text.auto.height"
    case .fixed: "custom.text.fixed.size"
    }
  }

  var isSystemImage: Bool { false }
}
