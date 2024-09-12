@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
@_spi(Internal) import IMGLYEditor
import IMGLYEngine
import SwiftUI

final class VideoInteractorBehavior: InteractorBehavior {
  func loadScene(_ context: InteractorContext, with _: EdgeInsets?) async throws {
    try loadSettings(context)

    try context.engine.editor.setSettingBool("touch/singlePointPanning", value: false)
    try context.engine.editor.setSettingBool("touch/dragStartCanSelect", value: false)
    try context.engine.editor.setSettingEnum("touch/pinchAction", value: "Scale")
    try context.engine.editor.setSettingEnum("touch/rotateAction", value: "Rotate")

    try context.engine.editor.setSettingBool("controlGizmo/showCropHandles", value: true)
    try context.engine.editor.setSettingBool("controlGizmo/showMoveHandles", value: false)
    try context.engine.editor.setSettingBool("controlGizmo/showResizeHandles", value: true)
    try context.engine.editor.setSettingBool("controlGizmo/showRotateHandles", value: false)
    try context.engine.editor.setSettingBool("controlGizmo/showScaleHandles", value: false)
    try context.engine.editor.setSettingColor(
      "page/innerBorderColor",
      color: .init(cgColor: UIColor.lightGray.withAlphaComponent(0.5).cgColor)!
    )

    // Make sure to set all settings before calling `onCreate` callback so that the consumer can change them if needed!
    try await context.interactor.config.callbacks.onCreate(context.engine)
  }

  func rootBottomBarItems(_ context: InteractorContext) throws -> [RootBottomBarItem] {
    var items: [RootBottomBarItem] = [
      .addFromPhotoRoll,
      .addFromCamera(systemCamera: false),
      .addOverlay,
      .addText,
      .addStickerOrShape,
      .addAudio,
      .addVoiceOver,
    ]

    if context.interactor.backgroundTracksItemCount > 1 {
      items.append(.reorder)
    }

    return items
  }

  func updateState(_: InteractorContext) throws {}
}

extension InteractorBehavior where Self == VideoInteractorBehavior {
  static var video: Self { Self() }
}
