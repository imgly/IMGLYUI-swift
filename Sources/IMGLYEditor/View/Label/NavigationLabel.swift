import SwiftUI

/// Label that looks like the original navigation back button.
@_spi(Internal) public struct NavigationLabel: View {
  @_spi(Internal) public enum Direction: String {
    case backward = "chevron.backward"
    case forward = "chevron.forward"
  }

  let title: LocalizedStringKey
  let direction: Direction

  @_spi(Internal) public init(_ title: LocalizedStringKey, direction: Direction) {
    self.title = title
    self.direction = direction
  }

  @_spi(Internal) public var body: some View {
    HStack(spacing: 4.5) {
      switch direction {
      case .backward:
        Image(systemName: direction.rawValue)
          .font(.headline)
          .padding(.leading, -8)
        Text(title)
      case .forward:
        Text(title)
        Image(systemName: direction.rawValue)
          .font(.headline)
          .padding(.trailing, -8)
      }
    }
    .padding(.bottom, 0.5)
  }
}
