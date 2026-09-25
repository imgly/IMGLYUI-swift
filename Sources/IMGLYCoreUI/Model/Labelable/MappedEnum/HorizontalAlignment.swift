import Foundation

@_spi(Internal) public enum HorizontalAlignment: String, MappedEnum, Labelable {
  case left = "Left"
  case center = "Center"
  case right = "Right"
  case auto = "Auto"

  @_spi(Internal) public var localizationValue: String.LocalizationValue {
    switch self {
    case .left: "ly_img_editor_sheet_format_text_alignment_horizontal_option_left"
    case .center: "ly_img_editor_sheet_format_text_alignment_horizontal_option_center"
    case .right: "ly_img_editor_sheet_format_text_alignment_horizontal_option_right"
    case .auto: "ly_img_editor_sheet_format_text_alignment_horizontal_option_auto"
    }
  }

  @_spi(Internal) public var imageName: String? {
    switch self {
    case .left: "text.alignleft"
    case .center: "text.aligncenter"
    case .right: "text.alignright"
    case .auto: "custom.text.align.left.auto"
    }
  }

  @_spi(Internal) public var isSystemImage: Bool {
    switch self {
    case .auto: false
    default: true
    }
  }

  /// Returns the appropriate image name for Auto alignment based on the effective alignment.
  /// - Parameter effectiveAlignment: The resolved alignment (Left or Right) for Auto alignment.
  /// - Returns: The image name for the dynamic Auto icon.
  @_spi(Internal) public func autoImageName(forEffectiveAlignment effectiveAlignment: HorizontalAlignment?) -> String {
    effectiveAlignment == .right ? "custom.text.align.right.auto" : "custom.text.align.left.auto"
  }
}
