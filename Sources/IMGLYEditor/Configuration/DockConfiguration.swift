import SwiftUI

// MARK: - Dock.Configuration

public extension Dock {
  /// Configuration for dock.
  struct Configuration {
    let items: Dock.Items?
    let modifications: [Dock.Modifications]
    @_spi(Internal) public let alignment: Dock.Alignment?
    @_spi(Internal) public let backgroundColor: Dock.BackgroundColor?
    @_spi(Internal) public let scrollDisabled: Dock.ScrollDisabled?

    /// Creates dock configuration.
    public init(_ configure: (inout Builder) -> Void) {
      var builder = Builder()
      configure(&builder)
      items = builder.items
      modifications = builder.modifications
      alignment = builder.alignment
      backgroundColor = builder.backgroundColor
      scrollDisabled = builder.scrollDisabled
    }

    /// Builder for dock configuration.
    public struct Builder { // swiftlint:disable:this nesting
      /// The dock items.
      var items: Dock.Items?

      /// The dock modifications.
      var modifications: [Dock.Modifications] = []

      /// The dock item alignment.
      public var alignment: Dock.Alignment?

      /// The dock background color.
      public var backgroundColor: Dock.BackgroundColor?

      /// Whether dock scrolling is disabled.
      public var scrollDisabled: Dock.ScrollDisabled?

      /// Sets the dock items using a result builder.
      public mutating func items(@Dock.Builder _ newItems: @escaping Dock.Items) {
        items = newItems
      }

      /// Adds a modification. Modifications accumulate in order.
      public mutating func modify(_ modification: @escaping Dock.Modifications) {
        modifications.append(modification)
      }
    }
  }
}
