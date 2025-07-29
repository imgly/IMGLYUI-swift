@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
@_spi(Internal) import IMGLYEditor
import IMGLYEngine
import SwiftUI

final class ApparelInteractorBehavior: InteractorBehavior {
  var historyResetOnPageChange: HistoryResetBehavior { .always }
  var deselectOnPageChange: Bool { true }

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

  func loadScene(_ context: InteractorContext, with insets: EdgeInsets?) async throws {
    try await DefaultInteractorBehavior.default.loadScene(context, with: insets)

    let scene = try context.engine.getScene()
    let page = try context.engine.getPage(context.interactor.page)
    _ = try context.engine.block.addOutline(Engine.outlineBlockName, for: page, to: scene)
    try context.engine.showOutline(false)
    try pageSetup(context)
  }

  func enableEditMode(_ context: InteractorContext) throws {
    try pageSetup(context)
  }

  func enablePreviewMode(_ context: InteractorContext, _ insets: EdgeInsets?) async throws {
    try disableCameraClamping(context)
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
