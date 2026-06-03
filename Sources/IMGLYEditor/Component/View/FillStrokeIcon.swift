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
      let showStroke = interactor.supportsStroke(id) && interactor.isAllowed(id, scope: .strokeChange)
      // Line-origin graphics surface their colour through the stroke section, so the fill is
      // hidden when a stroke section is available — matching the sheet this icon represents.
      let hideFillForLine = interactor.isLineOrigin(id) && showStroke
      let showFill = interactor.isColorFill(id) && !hideFillForLine &&
        interactor.supportsFill(id) && interactor.isAllowed(id, scope: .fillChange)
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
