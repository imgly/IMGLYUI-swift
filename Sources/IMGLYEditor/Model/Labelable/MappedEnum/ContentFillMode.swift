import Foundation
@_spi(Internal) import IMGLYCoreUI

enum ContentFillMode: String, MappedEnum, Labelable {
  case Cover
  case Crop
  case Contain

  var imageName: String? {
    switch self {
    case .Cover:
      "custom.fillmode.cover"
    case .Crop:
      "custom.fillmode.crop"
    case .Contain:
      "custom.fillmode.fit"
    }
  }

  var localizationValue: String.LocalizationValue {
    switch self {
    case .Crop:
      "ly_img_editor_sheet_crop_fill_mode_option_crop"
    case .Cover:
      "ly_img_editor_sheet_crop_fill_mode_option_cover"
    case .Contain:
      "ly_img_editor_sheet_crop_fill_mode_option_fit"
    }
  }

  var isSystemImage: Bool { false }
}
