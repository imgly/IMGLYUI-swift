import SwiftUI

@_spi(Internal) public struct SelectionColor: Identifiable {
  @_spi(Internal) public var id: CGColor { color }
  let color: CGColor
  @_spi(Internal) public let binding: Binding<CGColor>

  @_spi(Internal) public init(color: CGColor, binding: Binding<CGColor>) {
    self.color = color
    self.binding = binding
  }
}
