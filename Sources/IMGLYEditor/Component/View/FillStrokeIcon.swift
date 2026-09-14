import IMGLYEngine
import SwiftUI
@_spi(Internal) import IMGLYCore

/// A view that displays a fill and/or stroke color icon.
public struct FillStrokeIcon: View {
  @EnvironmentObject private var interactor: Interactor
  private let id: DesignBlockID

  /// Creates a fill and/or stroke color icon for a design block.
  /// - Parameter id: The id of the design block.
  public init(id: DesignBlockID) {
    self.id = id
  }

  public var body: some View {
    Group {
      let showFill = interactor.isColorFill(id) &&
        interactor.supportsFill(id) && interactor.isAllowed(id, scope: .fillChange)
      let showStroke = interactor.supportsStroke(id) && interactor.isAllowed(id, scope: .strokeChange)
      switch (showFill, showStroke) {
      case (true, true):
        AdaptiveOverlay {
          FillColorIcon()
        } overlay: {
          StrokeColorIcon()
        }
      case (true, false):
        FillColorIcon()
      case (false, true):
        StrokeColorIcon()
      case (false, false):
        EmptyView()
      }
    }
    .imgly.selection(id)
  }
}
