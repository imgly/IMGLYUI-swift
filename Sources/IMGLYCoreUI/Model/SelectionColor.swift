import SwiftUI

@_spi(Internal) public struct SelectionColor: Identifiable, Localizable {
  @_spi(Internal) public var description: String {
    guard let hsba = color.hsba else {
      return ""
    }
    return String(describing: hsba)
  }

  @_spi(Internal) public var id: CGColor { color }
  let color: CGColor
  @_spi(Internal) public let binding: Binding<CGColor>

  @_spi(Internal) public init(color: CGColor, binding: Binding<CGColor>) {
    self.color = color
    self.binding = binding
  }
}
