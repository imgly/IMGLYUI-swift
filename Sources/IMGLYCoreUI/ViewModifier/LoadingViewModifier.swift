@_spi(Internal) import IMGLYCore
import SwiftUI

/// A custom view modifier that applies a loading overlay with blur and disable effects.
struct LoadingModifier: ViewModifier {
  /// Indicates whether the loading overlay should be displayed.
  var isLoading: Bool

  func body(content: Content) -> some View {
    content
      .disabled(isLoading)
      .blur(radius: isLoading ? 3 : 0)
      .overlay(
        ProgressView()
          .opacity(isLoading ? 1 : 0) // Set the opacity of the overlay.
      )
  }
}

@_spi(Internal) public extension IMGLY where Wrapped: View {
  /// Applies the loading overlay modifier to the view.
  /// - Parameter isLoading: A Boolean value that indicates whether the loading overlay should be displayed.
  /// - Returns: The view with the loading overlay applied.
  func loadingOverlay(isLoading: Bool) -> some View {
    wrapped.modifier(LoadingModifier(isLoading: isLoading))
  }
}
