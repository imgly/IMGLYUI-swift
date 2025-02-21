import IMGLYEngine
import SwiftUI
@_spi(Internal) import IMGLYCore

public struct FillStrokeIcon: View {
  @EnvironmentObject private var interactor: Interactor
  private let id: DesignBlockID

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
