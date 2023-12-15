@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
@_spi(Internal) import IMGLYEditor
import IMGLYEngine
import SwiftUI
import UniformTypeIdentifiers

final class ApparelInteractorBehavior: InteractorBehavior {
  private func pageSetup(_ context: InteractorContext) throws {
    try context.engine.block.overrideAndRestore(
      context.engine.getPage(0),
      scopes: [.key(.fillChange), .key(.layerClipping)]
    ) {
      try context.engine.editor.setSettingBool("page/dimOutOfPageAreas", value: false)
      try context.engine.block.setClipped($0, clipped: true)
      try context.engine.block.set($0, property: .key(.fillEnabled), value: false)
      try context.engine.showOutline(false)
    }
  }

  func enableEditMode(_ context: InteractorContext) throws {
    try pageSetup(context)
  }

  func enablePreviewMode(_ context: InteractorContext, _ insets: EdgeInsets?) async throws {
    try await context.engine.zoomToBackdrop(insets)
    try context.engine.block.deselectAll()
    try pageSetup(context)
  }

  func isGestureActive(_ context: InteractorContext, _ started: Bool) throws {
    try context.engine.showOutline(started)
  }
}

extension InteractorBehavior where Self == ApparelInteractorBehavior {
  static var apparel: Self { Self() }
}
