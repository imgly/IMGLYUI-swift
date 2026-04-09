import SwiftUI

// MARK: - BottomPanel.Configuration

public extension BottomPanel {
  /// Configuration for the bottom panel.
  struct Configuration {
    let content: BottomPanel.Content?
    @_spi(Internal) public let animation: Animation?

    /// Creates bottom panel configuration.
    public init(_ configure: (inout Builder) -> Void) {
      var builder = Builder()
      configure(&builder)
      content = builder.content
      animation = builder.animation
    }

    /// Builder for bottom panel configuration.
    public struct Builder { // swiftlint:disable:this nesting
      /// The bottom panel content.
      public var content: BottomPanel.Content?

      /// The animation to use for resizing the canvas when the bottom panel changes size.
      @_spi(Internal) public var animation: Animation?

      /// Sets the bottom panel content using a view builder.
      public mutating func content(@ViewBuilder _ content: @escaping BottomPanel.Content) {
        self.content = content
      }
    }
  }
}
