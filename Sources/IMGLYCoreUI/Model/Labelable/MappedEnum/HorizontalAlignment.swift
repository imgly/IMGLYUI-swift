import Foundation

@_spi(Internal) public enum HorizontalAlignment: String, MappedEnum {
  case left = "Left"
  case center = "Center"
  case right = "Right"

  @_spi(Internal) public var description: String {
    switch self {
    case .left: "Align Left"
    case .center: "Align Horizontal Center"
    case .right: "Align Right"
    }
  }

  @_spi(Internal) public var imageName: String? {
    switch self {
    case .left: "text.alignleft"
    case .center: "text.aligncenter"
    case .right: "text.alignright"
    }
  }
}
