import SwiftUI

// MARK: - InspectorBar.Configuration

public extension InspectorBar {
  /// Configuration for inspector bar.
  struct Configuration {
    let items: InspectorBar.Items?
    let modifications: [InspectorBar.Modifications]
    @_spi(Internal) public let enabled: InspectorBar.Enabled?

    /// Creates inspector bar configuration.
    public init(_ configure: (inout Builder) -> Void) {
      var builder = Builder()
      configure(&builder)
      items = builder.items
      modifications = builder.modifications
      enabled = builder.enabled
    }

    /// Builder for inspector bar configuration.
    public struct Builder { // swiftlint:disable:this nesting
      /// The inspector bar items.
      var items: InspectorBar.Items?

      /// The inspector bar modifications.
      var modifications: [InspectorBar.Modifications] = []

      /// Whether the inspector bar is enabled.
      public var enabled: InspectorBar.Enabled?

      /// Sets the inspector bar items using a result builder.
      public mutating func items(@InspectorBar.Builder _ newItems: @escaping InspectorBar.Items) {
        items = newItems
      }

      /// Adds a modification. Modifications accumulate in order.
      public mutating func modify(_ modification: @escaping InspectorBar.Modifications) {
        modifications.append(modification)
      }
    }
  }
}
