import Foundation
@_spi(Internal) import IMGLYCoreUI

enum Adjustment: String, CaseIterable, Localizable {
  case brightness
  case saturation
  case contrast
  case gamma
  case clarity
  case exposure
  case shadows
  case highlights
  case blacks
  case whites
  case temperature
  case sharpness

  var localizationValue: String.LocalizationValue {
    switch self {
    case .brightness: "ly_img_editor_sheet_adjustments_label_brightness"
    case .saturation: "ly_img_editor_sheet_adjustments_label_saturation"
    case .contrast: "ly_img_editor_sheet_adjustments_label_contrast"
    case .gamma: "ly_img_editor_sheet_adjustments_label_gamma"
    case .clarity: "ly_img_editor_sheet_adjustments_label_clarity"
    case .exposure: "ly_img_editor_sheet_adjustments_label_exposure"
    case .shadows: "ly_img_editor_sheet_adjustments_label_shadows"
    case .highlights: "ly_img_editor_sheet_adjustments_label_highlights"
    case .blacks: "ly_img_editor_sheet_adjustments_label_blacks"
    case .whites: "ly_img_editor_sheet_adjustments_label_whites"
    case .temperature: "ly_img_editor_sheet_adjustments_label_temperature"
    case .sharpness: "ly_img_editor_sheet_adjustments_label_sharpness"
    }
  }
}
