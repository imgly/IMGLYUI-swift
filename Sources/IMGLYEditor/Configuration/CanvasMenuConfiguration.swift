import SwiftUI

// MARK: - CanvasMenu.Configuration

public extension CanvasMenu {
  /// Configuration for canvas menu.
  struct Configuration {
    let items: CanvasMenu.Items?
    let modifications: [CanvasMenu.Modifications]

    /// Creates canvas menu configuration.
    public init(_ configure: (inout Builder) -> Void) {
      var builder = Builder()
      configure(&builder)
      items = builder.items
      modifications = builder.modifications
    }

    /// Builder for canvas menu configuration.
    public struct Builder { // swiftlint:disable:this nesting
      /// The canvas menu items.
      var items: CanvasMenu.Items?

      /// The canvas menu modifications.
      var modifications: [CanvasMenu.Modifications] = []

      /// Sets the canvas menu items using a result builder.
      public mutating func items(@CanvasMenu.Builder _ newItems: @escaping CanvasMenu.Items) {
        items = newItems
      }

      /// Adds a modification. Modifications accumulate in order.
      public mutating func modify(_ modification: @escaping CanvasMenu.Modifications) {
        modifications.append(modification)
      }
    }
  }
}
