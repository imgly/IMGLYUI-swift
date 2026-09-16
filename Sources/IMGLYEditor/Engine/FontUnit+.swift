import Foundation
import IMGLYEngine
@_spi(Internal) import IMGLYCoreUI

@_spi(Internal) extension FontUnit: Localizable {
  @_spi(Internal) public var localizationValue: String.LocalizationValue {
    switch self {
    case .px: "ly_img_editor_dialog_resize_unit_option_pixel"
    case .pt: "ly_img_editor_dialog_resize_unit_option_point"
    @unknown default: "ly_img_editor_dialog_resize_unit_option_point"
    }
  }

  var abbreviation: String {
    switch self {
    case .px: "px"
    case .pt: "pt"
    @unknown default: "pt"
    }
  }
}
