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

@_spi(Internal) public enum RootBottomBarItem: IdentifiableByHash {
  case fab, selectionColors
  case font(_ id: DesignBlockID, fontFamilies: [String]? = nil)
  case fontSize(_ id: DesignBlockID)
  case color(_ id: DesignBlockID, colorPalette: [NamedColor]? = nil)
  case reorder

  case adjustments(_ id: DesignBlockID)
  case filter(_ id: DesignBlockID)
  case effect(_ id: DesignBlockID)
  case blur(_ id: DesignBlockID)

  @_spi(Internal) public struct Action: Hashable {
    @_spi(Internal) public static func == (_: Self, _: Self) -> Bool {
      true
    }

    @_spi(Internal) public func hash(into _: inout Hasher) {}

    let action: () throws -> Void

    @_spi(Internal) public init(action: @escaping () throws -> Void = {}) {
      self.action = action
    }
  }

  case crop(_ id: DesignBlockID, enter: Action, exit: Action)

  case addElements
  case addFromPhotoRoll
  case addFromCamera(systemCamera: Bool)
  case addOverlay
  case addImage
  case addText
  case addShape
  case addSticker
  case addStickerOrShape
  case addAudio
  case addVoiceOver

  var sheetMode: SheetMode {
    switch self {
    case .fab: .add
    case .selectionColors: .selectionColors
    case .reorder: .reorder
    case let .font(id, families): .font(id, families)
    case let .fontSize(id): .fontSize(id)
    case let .color(id, palette): .color(id, palette)
    case let .adjustments(id): .adjustments(id)
    case let .filter(id): .filter(id)
    case let .effect(id): .effect(id)
    case let .blur(id): .blur(id)
    case let .crop(id, enter, exit): .crop(id, enter, exit)
    case .addElements: .addElements
    case .addFromPhotoRoll: .addFromPhotoRoll
    case let .addFromCamera(systemCamera): .addFromCamera(systemCamera)
    case .addOverlay: .addOverlay
    case .addImage: .addImage
    case .addText: .addText
    case .addShape: .addShape
    case .addSticker: .addSticker
    case .addStickerOrShape: .addStickerOrShape
    case .addAudio: .addAudio
    case .addVoiceOver: .addVoiceOver
    }
  }
}

@_spi(Internal) public enum PreviewMode {
  case fixed
  case scrollable
}

@MainActor
@_spi(Internal) public protocol InteractorBehavior: Sendable {
  var historyResetOnPageChange: HistoryResetBehavior { get }
  var deselectOnPageChange: Bool { get }
  var previewMode: PreviewMode { get }

  func loadScene(_ context: InteractorContext, with insets: EdgeInsets?) async throws
  func exportScene(_ context: InteractorContext) async throws
  func enableEditMode(_ context: InteractorContext) throws
  func enablePreviewMode(_ context: InteractorContext, _ insets: EdgeInsets?) async throws
  func isGestureActive(_ context: InteractorContext, _ started: Bool) throws
  func isBottomBarEnabled(_ context: InteractorContext) throws -> Bool
  func rootBottomBarItems(_ context: InteractorContext) throws -> [RootBottomBarItem]
  func pageChanged(_ context: InteractorContext) throws
  func historyChanged(_ context: InteractorContext) throws
  func updateState(_ context: InteractorContext) throws
}

@_spi(Internal) public extension InteractorBehavior {
  var historyResetOnPageChange: HistoryResetBehavior { .ifNeeded }
  var deselectOnPageChange: Bool { false }
  var previewMode: PreviewMode { .scrollable }

  func loadSettings(_ context: InteractorContext) throws {
    // Set role first as it affects other settings
    try context.engine.editor.setRole("Adopter")
    try context.engine.editor.setSettingBool("doubleClickToCropEnabled", value: true)

    try context.engine.editor.setSettingEnum("camera/clamping/overshootMode", value: "Center")
    let color: IMGLYEngine.Color = try context.engine.editor.getSettingColor("highlightColor")
    try context.engine.editor.setSettingColor("placeholderHighlightColor", color: color)

    try context.engine.editor.setSettingString(
      "basePath",
      value: context.interactor.config.settings.baseURL.absoluteString
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

    let scene = try context.engine.getScene()
    let page = try context.engine.getPage(context.interactor.page)
    _ = try context.engine.block.addOutline(Engine.outlineBlockName, for: page, to: scene)
    try context.engine.showOutline(false)
    try context.engine.showPage(context.interactor.page)
    try enableEditMode(context)
    let zoomLevel = try await context.engine.zoomToPage(
      context.interactor.page,
      context.interactor.zoomModel.defaultInsets,
      zoomModel: context.interactor.zoomModel
    )
    if let zoomLevel {
      context.interactor.zoomModel.defaultZoomLevel = zoomLevel
    }
  }

  func showAllPages(_ context: InteractorContext) throws {
    try context.engine.showAllPages(layout: context.interactor.verticalSizeClass == .compact ? .horizontal : .vertical)
  }

  func exportScene(_ context: InteractorContext) async throws {
    try await context.interactor.config.callbacks.onExport(context.engine, context.interactor)
  }

  func enableEditMode(_ context: InteractorContext) throws {
    try context.engine.showPage(context.interactor.page)
  }

  func enablePreviewMode(_ context: InteractorContext, _ insets: EdgeInsets?) async throws {
    try await enableScrollableCameraClamping(context, insets)
    try showAllPages(context)
    try context.engine.block.deselectAll()
    let pageID = try context.engine.getPage(context.interactor.page)
    try await context.engine.zoomToBlock(pageID, with: insets)
  }

  private func enableScrollableCameraClamping(_ context: InteractorContext, _ insets: EdgeInsets?) async throws {
    var updatedInsets = insets ?? .init()
    updatedInsets.leading += context.interactor.zoomModel.padding
    updatedInsets.trailing += context.interactor.zoomModel.padding
    updatedInsets.top += context.interactor.zoomModel.padding
    updatedInsets.bottom += context.interactor.zoomModel.padding

    let paddingLeft = Float(updatedInsets.leading)
    let paddingRight = Float(updatedInsets.trailing)
    let paddingTop = Float(updatedInsets.top)
    let paddingBottom = Float(updatedInsets.bottom)
    let margin = Float(context.interactor.zoomModel.defaultPadding + context.interactor.zoomModel.padding)

    guard let pages = try? context.engine.getSortedPages(), let firstPage = pages.first else {
      return
    }
    try context.engine.scene.unstable_enableCameraZoomClamping([firstPage], minZoomLimit: 1,
                                                               maxZoomLimit: 1,
                                                               paddingLeft: paddingLeft,
                                                               paddingTop: paddingTop,
                                                               paddingRight: paddingRight,
                                                               paddingBottom: paddingBottom)
    try context.engine.scene.unstable_enableCameraPositionClamping(pages,
                                                                   paddingLeft: paddingLeft - margin,
                                                                   paddingTop: paddingTop - margin,
                                                                   paddingRight: paddingRight - margin,
                                                                   paddingBottom: paddingBottom - margin,
                                                                   scaledPaddingLeft: margin,
                                                                   scaledPaddingTop: margin,
                                                                   scaledPaddingRight: margin,
                                                                   scaledPaddingBottom: margin)
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

  func isGestureActive(_: InteractorContext, _: Bool) throws {}

  func isBottomBarEnabled(_: InteractorContext) throws -> Bool {
    true
  }

  func rootBottomBarItems(_: InteractorContext) throws -> [RootBottomBarItem] {
    [.fab]
  }

  func pageChanged(_ context: InteractorContext) throws {
    try context.engine.showPage(
      context.interactor.page,
      historyResetBehavior: historyResetOnPageChange,
      deselectAll: deselectOnPageChange
    )
  }

  func historyChanged(_: InteractorContext) throws {}

  func updateState(_ context: InteractorContext) throws {
    guard !context.interactor.isLoading else {
      return
    }
    let selectionColors = try context.engine.selectionColors(forPage: context.interactor.page)
    if context.interactor.selectionColors != selectionColors {
      context.interactor.selectionColors = selectionColors
    }
  }
}

@_spi(Internal) public final class DefaultInteractorBehavior: InteractorBehavior {}

@_spi(Internal) public extension InteractorBehavior where Self == DefaultInteractorBehavior {
  static var `default`: Self { Self() }
}
