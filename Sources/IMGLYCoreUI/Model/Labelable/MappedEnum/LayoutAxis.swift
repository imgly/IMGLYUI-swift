import Foundation

@_spi(Internal) public enum LayoutAxis: String, MappedEnum {
  case vertical = "Vertical"
  case horizontal = "Horizontal"
  case depth = "Depth"

  @_spi(Internal) public var description: String { rawValue }

  @_spi(Internal) public var imageName: String? { nil }
}
