import Foundation
import IMGLYEngine
@_spi(Internal) import IMGLYCoreUI

@_spi(Internal) extension DesignUnit: Localizable {
  @_spi(Internal) public var localizationValue: String.LocalizationValue {
    switch self {
    case .px: "ly_img_editor_dialog_resize_unit_option_pixel"
    case .mm: "ly_img_editor_dialog_resize_unit_option_millimeter"
    case .in: "ly_img_editor_dialog_resize_unit_option_inch"
    @unknown default: "ly_img_editor_dialog_resize_unit_option_pixel"
    }
  }

  var abbreviation: String {
    switch self {
    case .px: "px"
    case .mm: "mm"
    case .in: "in"
    @unknown default: "px"
    }
  }
}
