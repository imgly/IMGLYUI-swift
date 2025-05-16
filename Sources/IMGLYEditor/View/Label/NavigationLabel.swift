import SwiftUI

/// A  label that looks like the original navigation back button.
public struct NavigationLabel: View {
  /// The direction of the navigation label.
  public enum Direction: String {
    case backward = "chevron.backward"
    case forward = "chevron.forward"
  }

  let title: LocalizedStringKey
  let direction: Direction

  /// Creates a navigation label with a title and direction.
  /// - Parameters:
  ///   - title: The title of the label.
  ///   - direction: The direction of the label.
  public init(_ title: LocalizedStringKey, direction: Direction) {
    self.title = title
    self.direction = direction
  }

  public var body: some View {
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
