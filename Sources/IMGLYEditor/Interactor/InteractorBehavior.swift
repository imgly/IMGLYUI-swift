@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEngine
import SwiftUI
import UniformTypeIdentifiers

@MainActor
@_spi(Internal) public struct InteractorContext {
  @_spi(Internal) public let engine: Engine
  @_spi(Internal) public let interactor: Interactor

  init(_ engine: Engine, _ interactor: Interactor) {
    self.engine = engine
    self.interactor = interactor
  }
}

@_spi(Internal) public enum RootBottomBarItem: IdentifiableByHash {
  case fab, selectionColors
  case font(_ id: DesignBlockID, fontFamilies: [String]? = nil)
  case fontSize(_ id: DesignBlockID)
  case color(_ id: DesignBlockID, colorPalette: [NamedColor]? = nil)

  var sheetMode: SheetMode {
    switch self {
    case .fab: return .add
    case .selectionColors: return .selectionColors
    case let .font(id, families): return .font(id, families)
    case let .fontSize(id): return .fontSize(id)
    case let .color(id, palette): return .color(id, palette)
    }
  }
}

@MainActor
@_spi(Internal) public protocol InteractorBehavior: Sendable {
  func loadScene(_ context: InteractorContext, with insets: EdgeInsets?) async throws
  func exportScene(_ context: InteractorContext) async throws
  func enableEditMode(_ context: InteractorContext) throws
  func enablePreviewMode(_ context: InteractorContext, _ insets: EdgeInsets?) async throws
  func isGestureActive(_ context: InteractorContext, _ started: Bool) throws
  func rootBottomBarItems(_ context: InteractorContext) throws -> [RootBottomBarItem]
  func pageChanged(_ context: InteractorContext) throws
  func updateState(_ context: InteractorContext) throws
}

@_spi(Internal) public extension InteractorBehavior {
  func loadScene(_ context: InteractorContext, with insets: EdgeInsets?) async throws {
    try context.engine.editor.setSettingBool("touch/singlePointPanning", value: true)
    try context.engine.editor.setSettingBool("touch/dragStartCanSelect", value: false)
    try context.engine.editor.setSettingEnum("touch/pinchAction", value: "Zoom")
    try context.engine.editor.setSettingEnum("touch/rotateAction", value: "None")
    try context.engine.editor.setSettingBool("doubleClickToCropEnabled", value: true)
    try context.engine.editor.setSettingEnum("doubleClickSelectionMode", value: "Direct")
    try context.engine.editor.setSettingString(
      "basePath",
      value: context.interactor.config.settings.baseURL.absoluteString
    )
    try context.engine.editor.setSettingEnum("role", value: "Adopter")
    try context.engine.editor.setSettingEnum("camera/clamping/overshootMode", value: "Center")
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

    let scene = try context.engine.getScene()
    let page = try context.engine.getPage(context.interactor.page)
    _ = try context.engine.block.addOutline(Engine.outlineBlockName, for: page, to: scene)
    try context.engine.showOutline(false)
    try context.engine.showPage(context.interactor.page)
    try enableEditMode(context)
    var zoomModel = context.interactor.zoomModel
    try await context.engine.zoomToPage(context.interactor.page, insets, zoomModel: &zoomModel)
    context.interactor.zoomModel = zoomModel
    try context.engine.editor.resetHistory()
  }

  private func showAllPages(_ context: InteractorContext) throws {
    try context.engine.showAllPages(layout: context.interactor.verticalSizeClass == .compact ? .horizontal : .vertical)
  }

  func exportScene(_ context: InteractorContext) async throws {
    try await context.interactor.config.callbacks.onExport(context.engine, context.interactor)
  }

  func enableEditMode(_ context: InteractorContext) throws {
    try context.engine.showPage(context.interactor.page)
  }

  func enablePreviewMode(_ context: InteractorContext, _ insets: EdgeInsets?) async throws {
    try showAllPages(context)
    try await context.engine.zoomToScene(insets)
    try context.engine.block.deselectAll()
  }

  func isGestureActive(_: InteractorContext, _: Bool) throws {}

  func rootBottomBarItems(_: InteractorContext) throws -> [RootBottomBarItem] {
    [.fab]
  }

  func pageChanged(_: InteractorContext) throws {}

  func updateState(_ context: InteractorContext) throws {
    guard !context.interactor.isLoading else {
      return
    }
    context.interactor.selectionColors = try context.engine.selectionColors(forPage: context.interactor.page)
  }
}

@_spi(Internal) public final class DefaultInteractorBehavior: InteractorBehavior {}

@_spi(Internal) public extension InteractorBehavior where Self == DefaultInteractorBehavior {
  static var `default`: Self { Self() }
}
