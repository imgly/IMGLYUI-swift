import SwiftUI

@_spi(Internal) public struct UndoRedoButtons: View {
  @EnvironmentObject private var interactor: Interactor

  @_spi(Internal) public init() {}

  @_spi(Internal) public var body: some View {
    Group {
      ActionButton(.undo)
        .disabled(!interactor.canUndo)
      ActionButton(.redo)
        .disabled(!interactor.canRedo)
    }
    .allowsHitTesting(interactor.isEditing)
    .opacity(interactor.isEditing ? 1 : 0)
    .animation(nil, value: interactor.isEditing)
  }
}
