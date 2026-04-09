import SwiftUI

// MARK: - NavigationBar.Configuration

public extension NavigationBar {
  /// Configuration for navigation bar.
  struct Configuration {
    let items: NavigationBar.Items?
    let modifications: [NavigationBar.Modifications]

    /// Creates navigation bar configuration.
    public init(_ configure: (inout Builder) -> Void) {
      var builder = Builder()
      configure(&builder)
      items = builder.items
      modifications = builder.modifications
    }

    /// Builder for navigation bar configuration.
    public struct Builder { // swiftlint:disable:this nesting
      /// The navigation bar items.
      var items: NavigationBar.Items?

      /// The navigation bar modifications.
      var modifications: [NavigationBar.Modifications] = []

      /// Sets the navigation bar items using a result builder.
      public mutating func items(@NavigationBar.Builder _ newItems: @escaping NavigationBar.Items) {
        items = newItems
      }

      /// Adds a modification. Modifications accumulate in order.
      public mutating func modify(_ modification: @escaping NavigationBar.Modifications) {
        modifications.append(modification)
      }
    }
  }
}
