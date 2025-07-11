@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
@_spi(Internal) import IMGLYEditor
import SwiftUI

final class PostcardInteractorBehavior: InteractorBehavior {
  var historyResetOnPageChange: HistoryResetBehavior { .always }
  var deselectOnPageChange: Bool { true }
  var previewMode: PreviewMode { .fixed }

  func loadScene(_ context: InteractorContext, with insets: EdgeInsets?) async throws {
    try await DefaultInteractorBehavior.default.loadScene(context, with: insets)
    context.interactor.selectionColors = try context.engine.selectionColors(
      forPage: 0,
      includeDisabled: true,
      setDisabled: true,
      ignoreScope: true
    )
    try context.engine.editor.setGlobalScope(key: ScopeKey.editorAdd.rawValue, value: .defer)
  }

  func enablePreviewMode(_ context: InteractorContext, _ insets: EdgeInsets?) async throws {
    try disableCameraClamping(context)
    try showAllPages(context)
    try await context.engine.zoomToScene(insets)
    try context.engine.block.deselectAll()
  }

  func updateState(_: InteractorContext) throws {}
}

extension InteractorBehavior where Self == PostcardInteractorBehavior {
  static var postcard: Self { Self() }
}
