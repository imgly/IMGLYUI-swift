@_spi(Internal) import IMGLYEditor
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEngine
import SwiftUI

final class VideoInteractorBehavior: InteractorBehavior {
  func loadScene(_ context: InteractorContext, with _: EdgeInsets?) async throws {
    try context.engine.editor.setSettingBool("touch/singlePointPanning", value: false)
    try context.engine.editor.setSettingBool("touch/dragStartCanSelect", value: false)
    try context.engine.editor.setSettingEnum("touch/pinchAction", value: "Scale")
    try context.engine.editor.setSettingEnum("touch/rotateAction", value: "Rotate")
    try context.engine.editor.setSettingBool("doubleClickToCropEnabled", value: true)
    try context.engine.editor.setSettingEnum("doubleClickSelectionMode", value: "Direct")

    try context.engine.editor.setSettingBool("controlGizmo/showCropHandles", value: true)
    try context.engine.editor.setSettingBool("controlGizmo/showResizeHandles", value: true)
    try context.engine.editor.setSettingBool("controlGizmo/showRotateHandles", value: false)
    try context.engine.editor.setSettingBool("controlGizmo/showScaleHandles", value: false)
    try context.engine.editor.setSettingEnum("camera/clamping/overshootMode", value: "Center")

    try context.engine.editor.setSettingString(
      "basePath",
      value: context.interactor.config.settings.baseURL.absoluteString
    )

    try context.engine.editor.setSettingEnum("role", value: "Adopter")
    try [ScopeKey]([
      .appearanceAdjustments,
      .appearanceFilter,
      .appearanceEffect,
      .appearanceBlur,
      .appearanceShadow,

      // .editorAdd, // Cannot be restricted in web Dektop UI for now.
      .editorSelect,

      .fillChange,
      .fillChangeType,

      .layerCrop,
      .layerMove,
      .layerResize,
      .layerRotate,
      .layerFlip,
      .layerOpacity,
      .layerBlendMode,
      .layerVisibility,
      .layerClipping,

      .lifecycleDestroy,
      .lifecycleDuplicate,

      .strokeChange,

      .shapeChange,

      .textEdit,
      .textCharacter
    ]).forEach { scope in
      try context.engine.editor.setGlobalScope(key: scope.rawValue, value: .defer)
    }

    try await context.interactor.config.callbacks.onCreate(context.engine)

    try context.engine.editor.setSettingColor(
      "page/innerBorderColor",
      color: .init(cgColor: UIColor.lightGray.withAlphaComponent(0.5).cgColor)!
    )

    try context.engine.editor.resetHistory()
  }

  func rootBottomBarItems(_ context: InteractorContext) throws -> [RootBottomBarItem] {
    var items: [RootBottomBarItem] = [
      .openCameraRoll,
      .openCamera,
      .openOverlayLibrary,
      .addText,
      .addSticker,
      .addAudio
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
