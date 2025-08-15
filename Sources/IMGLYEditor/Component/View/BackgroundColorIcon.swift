import IMGLYEngine
import SwiftUI
@_spi(Internal) import IMGLYCore

/// A view that displays a background color icon.
public struct BackgroundColorIcon: View {
  @EnvironmentObject private var interactor: Interactor
  private let id: DesignBlockID

  /// Creates a background color icon for a design block.
  /// - Parameter id: The id of the design block.
  public init(id: DesignBlockID) {
    self.id = id
  }

  /// Checks if the background color is enabled for the  block.
  private var isBackgroundEnabled: Bool {
    interactor.bind(id, property: .key(.backgroundColorEnabled), default: false).wrappedValue
  }

  /// Gets the background color for the  block.
  private var backgroundColor: Binding<CGColor> {
    interactor.bind(
      id,
      property: .key(.backgroundColorColor),
      default: .imgly.white
    )
  }

  public var body: some View {
    FillColorImage(
      isEnabled: isBackgroundEnabled,
      color: backgroundColor
    )
    .imgly.selection(id)
  }
}
