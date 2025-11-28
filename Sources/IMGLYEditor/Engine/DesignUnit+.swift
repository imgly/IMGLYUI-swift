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

@_spi(Internal) extension DesignUnit {
  /// Converts a value from one design unit to another.
  ///
  /// - Parameters:
  ///   - value: The value to convert
  ///   - from: The source design unit
  ///   - to: The target design unit
  ///   - dpi: Dots per inch (used for px conversions)
  ///   - pixelScale: Pixel scale factor (used for px conversions)
  /// - Returns: The converted value
  @_spi(Internal) static func convert<T: BinaryFloatingPoint>(
    _ value: T,
    from: Self,
    to: Self,
    dpi: T,
    pixelScale: T
  ) -> T {
    let mmPerInch: T = 25.4

    // Convert to inches as intermediate unit
    let valueInInches: T = switch from {
    case .in: value
    case .mm: value / mmPerInch
    case .px: value / (dpi * pixelScale)
    default: value
    }

    // Convert from inches to target unit
    let convertedValue: T = switch to {
    case .in: valueInInches
    case .mm: valueInInches * mmPerInch
    case .px: valueInInches * dpi * pixelScale
    default: value
    }

    return convertedValue
  }
}
