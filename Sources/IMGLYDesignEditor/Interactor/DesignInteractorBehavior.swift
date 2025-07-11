@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
@_spi(Internal) import IMGLYEditor
import SwiftUI

final class DesignInteractorBehavior: InteractorBehavior {
  func loadScene(_ context: InteractorContext, with _: EdgeInsets?) async throws {
    try loadSettings(context)

    try context.engine.editor.setSettingBool("touch/singlePointPanning", value: true)
    try context.engine.editor.setSettingBool("touch/dragStartCanSelect", value: false)
    try context.engine.editor.setSettingEnum("touch/pinchAction", value: "Zoom")
    try context.engine.editor.setSettingEnum("touch/rotateAction", value: "None")

    // Make sure to set all settings before calling `onCreate` callback so that the consumer can change them if needed!
    try await context.interactor.config.callbacks.onCreate(context.engine)

    // features/pageCarouselEnabled needs horizontal stack if present.
    if let stack = try? context.engine.getStack() {
      try context.engine.block.set(stack, property: .key(.stackAxis), value: LayoutAxis.horizontal)
    }

    try context.engine.block.deselectAll()
    let zoomLevel = try await context.engine.zoomToPage(
      context.interactor.page,
      context.interactor.zoomModel.defaultInsets,
      zoomModel: context.interactor.zoomModel
    )
    if let zoomLevel {
      context.interactor.zoomModel.defaultZoomLevel = zoomLevel
    }

    try context.engine.editor.setSettingBool("features/pageCarouselEnabled", value: true)
  }

  func enableEditMode(_: InteractorContext) throws {}
  func enablePreviewMode(_: InteractorContext, _: EdgeInsets?) async throws {}

  func pageChanged(_: InteractorContext) throws {}
  func updateState(_: InteractorContext) throws {}
}

extension InteractorBehavior where Self == DesignInteractorBehavior {
  static var design: Self { Self() }
}
