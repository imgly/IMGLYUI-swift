import SwiftUI

extension EnvironmentValues {
  /// Converts a swatch color to the color that the canvas draws. `View.imgly.interactor(_:)` sets it, so a swatch
  /// outside the editor, such as in a preview, draws its color as it is.
  @Entry var imglyDisplayColor: @MainActor (CGColor) -> CGColor = { $0 }
}
