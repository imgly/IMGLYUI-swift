@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEngine
import SwiftUI

@MainActor
@_spi(Internal) public struct InteractorContext {
  @_spi(Internal) public let engine: Engine
  @_spi(Internal) public let interactor: Interactor

  init(_ engine: Engine, _ interactor: Interactor) {
    self.engine = engine
    self.interactor = interactor
  }
}

@MainActor
@_spi(Internal) public protocol InteractorBehavior: Sendable {
  var unselectedPageCrop: Bool { get }

  func loadScene(_ context: InteractorContext, with insets: EdgeInsets?) async throws
  func enableEditMode(_ context: InteractorContext) throws
  func enablePreviewMode(_ context: InteractorContext, _ insets: EdgeInsets?) async throws
  func isBottomBarEnabled(_ context: InteractorContext) throws -> Bool
  func historyChanged(_ context: InteractorContext) throws
}

@_spi(Internal) public extension InteractorBehavior {
  var unselectedPageCrop: Bool { false }

  func loadSettings(_ context: InteractorContext) throws {
    // Set role first as it affects other settings
    try context.engine.editor.setRole("Adopter")
    try context.engine.editor.setSettingBool("doubleClickToCropEnabled", value: true)

    try context.engine.editor.setSettingEnum("camera/clamping/overshootMode", value: "Center")
    let color: IMGLYEngine.Color = try context.engine.editor.getSettingColor("highlightColor")
    try context.engine.editor.setSettingColor("placeholderHighlightColor", color: color)

    try context.engine.editor.setSettingBool("features/removeForegroundTracksOnSceneLoad", value: true)
    try context.engine.editor.setSettingBool("features/videoTranscodingEnabled",
                                             value: !FeatureFlags.isEnabled(.transcodePickerVideoImports))

    try context.engine.editor.setSettingString(
      "basePath",
      value: context.interactor.config.settings.baseURL.absoluteString,
    )

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
      .textCharacter,
    ]).forEach { scope in
      try context.engine.editor.setGlobalScope(key: scope.rawValue, value: .defer)
    }
  }

  func loadScene(_ context: InteractorContext, with _: EdgeInsets?) async throws {
    try loadSettings(context)

    try context.engine.editor.setSettingBool("touch/singlePointPanning", value: true)
    try context.engine.editor.setSettingBool("touch/dragStartCanSelect", value: false)
    try context.engine.editor.setSettingEnum("touch/pinchAction", value: "Zoom")
    try context.engine.editor.setSettingEnum("touch/rotateAction", value: "None")

    // Make sure to set all settings before calling `onCreate` callback so that the consumer can change them if needed!
    try await context.interactor.config.callbacks.onCreate(context.engine)

    try context.engine.showPage(context.interactor.page)
    try enableEditMode(context)
    let zoomLevel = try await context.engine.zoomToPage(
      context.interactor.page,
      context.interactor.zoomModel.defaultInsets,
      zoomModel: context.interactor.zoomModel,
    )
    if let zoomLevel {
      context.interactor.zoomModel.defaultZoomLevel = zoomLevel
    }
  }

  func showAllPages(_ context: InteractorContext) throws {
    try context.engine.showAllPages(layout: context.interactor.verticalSizeClass == .compact ? .horizontal : .vertical)
  }

  func enableEditMode(_ context: InteractorContext) throws {
    try context.engine.showPage(context.interactor.page)
  }

  func enablePreviewMode(_ context: InteractorContext, _ insets: EdgeInsets?) async throws {
    try disableCameraClamping(context)
    try showAllPages(context)
    try context.engine.block.deselectAll()
    let pageID = try context.engine.getPage(context.interactor.page)
    try await context.engine.zoomToBlock(pageID, with: insets)
  }

  func disableCameraClamping(_ context: InteractorContext) throws {
    let scene = try context.engine.getScene()
    if try context.engine.scene.unstable_isCameraZoomClampingEnabled(scene) {
      try context.engine.scene.unstable_disableCameraZoomClamping()
    }
    if try context.engine.scene.unstable_isCameraPositionClampingEnabled(scene) {
      try context.engine.scene.unstable_disableCameraPositionClamping()
    }
  }

  func isBottomBarEnabled(_: InteractorContext) throws -> Bool {
    true
  }

  func historyChanged(_: InteractorContext) throws {}
}

@_spi(Internal) public final class DefaultInteractorBehavior: InteractorBehavior {}

@_spi(Internal) public extension InteractorBehavior where Self == DefaultInteractorBehavior {
  static var `default`: Self { Self() }
}
