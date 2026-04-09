import Foundation
import SwiftUI
@_spi(Internal) import IMGLYCoreUI
import UniformTypeIdentifiers
@_spi(Internal) import struct IMGLYCore.Error
import IMGLYEngine

// MARK: - Callbacks

/// A namespace for `onCreate` callbacks.
public enum OnCreate {
  /// The callback type.
  public typealias Callback = @MainActor (_ engine: Engine) async throws -> Void

  /// The handler type that receives an `existing` closure for chaining.
  public typealias Handler = @MainActor (
    _ engine: Engine,
    _ existing: () async throws -> Void
  ) async throws -> Void

  /// The default callback which creates a new scene.
  public static let `default`: Callback = { engine in
    let scene = try engine.scene.create()
    let page = try engine.block.create(.page)
    try engine.block.appendChild(to: scene, child: page)
    try engine.block.setWidth(page, value: 1080)
    try engine.block.setHeight(page, value: 1080)
  }

  /// Creates a callback that loads a scene.
  /// - Parameter url: The URL of the scene file.
  /// - Returns: The callback.
  public static func loadScene(from url: URL) -> Callback {
    { engine in
      try await engine.scene.load(from: url)
    }
  }

  /// Applies base engine settings that are common across all editor solutions.
  /// This includes role, editor settings, camera clamping, touch settings, and global scopes.
  public static let applyBaseSettings: Callback = { engine in
    try engine.editor.setRole("Adopter")
    try engine.editor.setSettingBool("doubleClickToCropEnabled", value: true)

    try engine.editor.setSettingEnum("camera/clamping/overshootMode", value: "Center")
    let color: IMGLYEngine.Color = try engine.editor.getSettingColor("highlightColor")
    try engine.editor.setSettingColor("placeholderHighlightColor", color: color)

    try engine.editor.setSettingBool("features/removeForegroundTracksOnSceneLoad", value: true)
    try engine.editor.setSettingBool("features/videoTranscodingEnabled",
                                     value: !FeatureFlags.isEnabled(.transcodePickerVideoImports))

    try engine.editor.setSettingBool("touch/singlePointPanning", value: true)
    try engine.editor.setSettingBool("touch/dragStartCanSelect", value: false)
    try engine.editor.setSettingEnum("touch/pinchAction", value: "Zoom")
    try engine.editor.setSettingEnum("touch/rotateAction", value: "None")

    try [ScopeKey]([
      .appearanceAdjustments,
      .appearanceFilter,
      .appearanceEffect,
      .appearanceBlur,
      .appearanceShadow,

      // .editorAdd, // Cannot be restricted in web Desktop UI for now.
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
      try engine.editor.setGlobalScope(key: scope.rawValue, value: .defer)
    }
  }
}

/// A namespace for `onExport` callbacks.
public enum OnExport {
  /// The callback type.
  public typealias Callback = @MainActor (_ engine: Engine, _ eventHandler: EditorEventHandler) async throws
    -> Void

  /// The handler type that receives an `existing` closure for chaining.
  public typealias Handler = @MainActor (
    _ engine: Engine,
    _ eventHandler: EditorEventHandler,
    _ existing: () async throws -> Void
  ) async throws -> Void

  /// Creates a callback that exports the scene as a static file (e.g., PDF, PNG), writes it to a temporary file,
  /// and opens a system dialog for sharing the exported file.
  /// - Parameter mimeType: Optional mime type of the export. If `nil`, `MIMEType.pdf` is used.
  /// - Returns: The callback.
  public static func `static`(mimeType: MIMEType? = nil) -> Callback {
    { engine, eventHandler in
      let (data, contentType) = try await export(engine, mimeType: mimeType)
      let url = FileManager.default.temporaryDirectory.appendingPathComponent("Export", conformingTo: contentType)
      try data.write(to: url, options: [.atomic])
      eventHandler.send(.shareFile(url))
    }
  }

  /// Creates a callback that exports the scene as a video file (e.g., MP4), displays a progress indicator,
  /// writes it to a temporary file, and opens a system dialog for sharing the exported file.
  /// - Parameter mimeType: Optional mime type of the export. If `nil`, `MIMEType.mp4` is used.
  /// - Returns: The callback.
  public static func video(mimeType: MIMEType? = nil) -> Callback {
    { engine, eventHandler in
      guard let page = try engine.scene.getCurrentPage() else {
        throw EditorError("No page found.")
      }
      let pageDuration = try engine.block.getDuration(page)
      let constraints = (eventHandler as? VideoDurationConstraintsProviding)?
        .videoDurationConstraints
        .normalized()
      let minimumDuration = constraints?.minimumDuration
      let maximumDuration = constraints?.maximumDuration
      if let minimumDuration, pageDuration < minimumDuration {
        eventHandler.send(.showVideoMinLengthAlert(minimumVideoDuration: minimumDuration))
        return
      }
      let exportDuration = maximumDuration.map { min(pageDuration, $0) }
      let (data, contentType) = try await exportVideo(
        engine,
        eventHandler,
        mimeType: mimeType,
        duration: exportDuration,
      )

      let url = FileManager.default.temporaryDirectory.appendingPathComponent("Export", conformingTo: contentType)
      try data.write(to: url, options: [.atomic])
      eventHandler.send(.exportCompleted { eventHandler.send(.shareFile(url)) })
    }
  }

  /// A utility that calls `BlockAPI.export`.
  /// - Parameters:
  ///   - engine: The used engine.
  ///   - mimeType: Optional mime type of the export. If `nil` `MIMEType.pdf` is used.
  /// - Returns: The exported data and type.
  @MainActor
  public static func export(_ engine: Engine, mimeType: MIMEType? = nil) async throws -> (Data, UTType) {
    guard let scene = try engine.scene.get() else {
      throw EditorError("No scene was found.")
    }
    let mimeType = mimeType ?? .pdf
    let data = try await engine.block.export(scene, mimeType: mimeType) { engine in
      try engine.scene.getPages().forEach {
        try engine.block.setScopeEnabled($0, key: "layer/visibility", enabled: true)
        try engine.block.setVisible($0, visible: true)
      }
    }
    return (data, mimeType.uniformType)
  }

  /// A utility that calls `BlockAPI.exportVideo` and displays a progress indicator.
  /// - Parameters:
  ///   - engine: The used engine.
  ///   - eventHandler: The used event handler.
  ///   - mimeType: Optional mime type of the export. If `nil` `MIMEType.mp4` is used.
  ///   - duration: Optional duration in seconds used to clamp the export length.
  /// - Returns: The exported data and type.
  @MainActor
  public static func exportVideo(_ engine: Engine, _ eventHandler: EditorEventHandler,
                                 mimeType: MIMEType? = nil,
                                 duration: TimeInterval? = nil) async throws -> (Data, UTType) {
    guard let page = try engine.scene.getCurrentPage() else {
      throw EditorError("No page was found.")
    }
    eventHandler.send(.exportProgress(.relative(0)))
    let mimeType = mimeType ?? .mp4
    let options = VideoExportOptions(duration: duration ?? 0)
    let stream = try await engine.block.exportVideo(page, mimeType: mimeType, options: options) { _ in }

    var lastReportedProgress = 0
    for try await export in stream {
      try Task.checkCancellation()
      switch export {
      case let .progress(_, encodedFrames, totalFrames):
        let progress = Int((Float(encodedFrames) / Float(totalFrames)) * 100)
        // Only send event if we've moved beyond the last integer value.
        if progress > lastReportedProgress {
          lastReportedProgress = progress
          eventHandler.send(.exportProgress(.relative(Float(progress) / 100)))
        }
      case let .finished(video: videoData):
        return (videoData, mimeType.uniformType)
      }
    }
    try Task.checkCancellation()
    throw EditorError("Failed to export the content.")
  }
}

/// A namespace for `onUpload` callbacks.
public enum OnUpload {
  /// The callback type.
  public typealias Callback = @MainActor (
    _ engine: Engine,
    _ sourceID: String,
    _ asset: AssetDefinition
  ) async throws -> AssetDefinition

  /// The handler type that receives an `existing` closure for chaining.
  /// Call `existing` with the (potentially modified) asset to continue the chain.
  public typealias Handler = @MainActor (
    _ engine: Engine,
    _ sourceID: String,
    _ asset: AssetDefinition,
    _ existing: (AssetDefinition) async throws -> AssetDefinition
  ) async throws -> AssetDefinition

  /// The default callback which forwards the unmodified `AssetDefinition`.
  public static let `default`: Callback = { _, _, asset in
    asset
  }
}

/// A namespace for `onClose` callbacks.
public enum OnClose {
  /// The callback type.
  public typealias Callback = @MainActor (
    _ engine: Engine,
    _ eventHandler: EditorEventHandler
  ) -> Void

  /// The handler type that receives an `existing` closure for chaining.
  public typealias Handler = @MainActor (
    _ engine: Engine,
    _ eventHandler: EditorEventHandler,
    _ existing: () -> Void
  ) -> Void

  /// The default callback that displays the close confirmation alert if there are any unsaved changes, else closes the
  /// editor.
  public static let `default`: Callback = { engine, eventHandler in
    let hasUnsavedChanges = (try? engine.editor.canUndo()) ?? false

    if hasUnsavedChanges {
      eventHandler.send(.showCloseConfirmationAlert)
    } else {
      eventHandler.send(.closeEditor)
    }
  }
}

/// A namespace for `onError` callbacks.
public enum OnError {
  /// The callback type.
  public typealias Callback = @MainActor (
    _ error: Swift.Error,
    _ eventHandler: EditorEventHandler
  ) -> Void

  /// The handler type that receives an `existing` closure for chaining.
  public typealias Handler = @MainActor (
    _ error: Swift.Error,
    _ eventHandler: EditorEventHandler,
    _ existing: () -> Void
  ) -> Void

  /// The default callback that displays the error alert.
  public static let `default`: Callback = { error, eventHandler in
    eventHandler.send(.showErrorAlert(error))
  }
}

/// A namespace for `onLoaded` callbacks.
public enum OnLoaded {
  /// The callback type.
  public typealias Callback = @MainActor (_ context: OnLoaded.Context) async throws
    -> Void

  /// The handler type that receives an `existing` closure for chaining.
  public typealias Handler = @MainActor (
    _ context: OnLoaded.Context,
    _ existing: () async throws -> Void
  ) async throws -> Void

  /// The default empty callback.
  public static let `default`: Callback = { _ in }

  /// Collects async operations registered via ``Context/task(_:)`` during callback execution.
  @MainActor
  final class TaskCollector {
    private var operations: [@MainActor () async throws -> Void] = []

    func add(_ operation: @escaping @MainActor () async throws -> Void) {
      operations.append(operation)
    }

    var isEmpty: Bool { operations.isEmpty }

    /// Runs all collected operations concurrently.
    /// Blocks until all complete or one throws. Cancelling the parent task cancels all operations.
    func runAll() async throws {
      try await withThrowingTaskGroup(of: Void.self) { group in
        for operation in operations {
          group.addTask {
            try await operation()
          }
        }
        operations = []
        try await group.waitForAll()
      }
    }
  }

  /// The context of the ``OnLoaded/Callback``.
  @MainActor
  public struct Context {
    /// The engine of the current editor.
    public let engine: Engine
    /// The event handler of the current editor.
    public let eventHandler: EditorEventHandler
    /// The configured ``IMGLYCoreUI/AssetLibrary``.
    public let assetLibrary: any AssetLibrary

    let taskCollector: TaskCollector

    /// Registers async work that runs for the editor's lifetime.
    ///
    /// Use this to set up long-lived engine subscriptions without blocking the callback chain.
    /// Registered tasks start after all `onLoaded` callbacks complete and are automatically
    /// cancelled when the editor is dismissed.
    ///
    /// ```swift
    /// .imgly.onLoaded { context in
    ///   context.task {
    ///     for try await _ in context.engine.editor.onHistoryUpdated {
    ///       // React to history changes
    ///     }
    ///   }
    /// }
    /// ```
    ///
    /// - Parameter operation: The async operation to run.
    public func task(_ operation: @escaping @MainActor () async throws -> Void) {
      taskCollector.add(operation)
    }

    /// Updates the minimum and maximum video duration constraints at runtime.
    /// - Parameters:
    ///   - minimumVideoDuration: The minimum duration in seconds. Set to `nil` to disable.
    ///   - maximumVideoDuration: The maximum duration in seconds. Set to `nil` to disable.
    public func setVideoDurationConstraints(
      minimumVideoDuration: TimeInterval?,
      maximumVideoDuration: TimeInterval?,
    ) {
      eventHandler.send(.setVideoDurationConstraints(
        minimumVideoDuration: minimumVideoDuration,
        maximumVideoDuration: maximumVideoDuration,
      ))
    }
  }
}

/// A namespace for `onChanged` callbacks.
public enum OnChanged {
  /// The callback type.
  public typealias Callback = @Sendable @MainActor (
    _ update: OnChanged.EditorStateChange,
    _ context: OnChanged.Context
  ) throws -> Void

  /// The handler type that receives an `existing` closure for chaining.
  public typealias Handler = @Sendable @MainActor (
    _ update: OnChanged.EditorStateChange,
    _ context: OnChanged.Context,
    _ existing: () throws -> Void
  ) throws -> Void

  /// The default callback.
  ///
  /// The following state updates are handled by default:
  /// - `EditorStateChange.page`: Sets the new page visible unless `features/pageCarouselEnabled` is enabled.
  public static let `default`: Callback = { update, context in
    switch update {
    case let .page(_, page):
      if try !context.engine.editor.getSettingBool("features/pageCarouselEnabled") {
        let resetHistory = try !(context.engine.editor.canUndo() || context.engine.editor.canRedo())
        try context.engine.showPage(page, resetHistory: resetHistory, deselectAll: false)
      }
    case let .viewMode(_, state):
      guard try !context.engine.editor.getSettingBool("features/pageCarouselEnabled") else {
        return
      }
      if state.editorViewMode == .edit {
        try context.engine.showPage(state.pageIndex)
      } else if state.editorViewMode == .preview {
        Task {
          // Disable camera clamping.
          let scene = try context.engine.getScene()
          if try context.engine.scene.unstable_isCameraZoomClampingEnabled(scene) {
            try context.engine.scene.unstable_disableCameraZoomClamping()
          }
          if try context.engine.scene.unstable_isCameraPositionClampingEnabled(scene) {
            try context.engine.scene.unstable_disableCameraPositionClamping()
          }
          let layoutAxis: LayoutAxis = state.verticalSizeClass == .compact ? .horizontal : .vertical
          try context.engine.showAllPages(layout: layoutAxis)
          try context.engine.block.deselectAll()
          let page = state.pageIndex
          let pageID = try context.engine.getPage(page)
          try await context.engine.zoomToBlock(pageID, with: state.insets)
        }
      }
    default:
      break
    }
  }

  /// The context of the ``OnChanged/Callback``.
  public struct Context {
    /// The engine of the current editor.
    public let engine: Engine
    /// The event handler of the current editor.
    public let eventHandler: EditorEventHandler
  }

  /// A namespace for the editor state updates received through the ``OnChanged/Callback``.
  public enum EditorStateChange {
    /// The canvas started/ended receiving a touch gesture.
    /// - Parameters:
    ///   - oldValue: The old value before the state change.
    ///   - newValue: The new value after the state change.
    case gestureActive(oldValue: Bool, newValue: Bool)
    /// The current page index changed.
    /// - Parameters:
    ///   - oldValue: The old value before the state change.
    ///   - newValue: The new value after the state change.
    case page(oldValue: Int, newValue: Int)
    /// The current edit mode changed.
    /// - Parameters:
    ///   - oldValue: The old value before the state change.
    ///   - newValue: The new value after the state change.
    case editMode(oldValue: IMGLYEngine.EditMode, newValue: IMGLYEngine.EditMode)
    /// The current view mode changed.
    /// - Parameters:
    ///   - oldValue: The old value before the state change.
    ///   - newValue: The new value after the state change.
    case viewMode(oldValue: ViewModeState, newValue: ViewModeState)
  }

  /// The view mode state of the editor.
  public struct ViewModeState {
    /// The currently active view mode.
    public let editorViewMode: EditorViewMode
    /// The index of the currently visible page.
    public let pageIndex: Int
    /// The insets of the canvas.
    public let insets: EdgeInsets?
    /// The current `@Environment(\.verticalSizeClass)`.
    public let verticalSizeClass: UserInterfaceSizeClass?
  }
}

// MARK: - Internal interface

@_spi(Internal) public struct EngineCallbacks {
  @_spi(Internal) public let onCreate: OnCreate.Callback
  let onLoaded: OnLoaded.Callback
  let onExport: OnExport.Callback
  let onUpload: OnUpload.Callback
  let onClose: OnClose.Callback
  let onError: OnError.Callback
  let onChanged: OnChanged.Callback

  init(
    onCreate: @escaping OnCreate.Callback = OnCreate.default,
    onLoaded: @escaping OnLoaded.Callback = OnLoaded.default,
    onExport: @escaping OnExport.Callback = { _, _ in print("OnExport not implemented.") },
    onUpload: @escaping OnUpload.Callback = OnUpload.default,
    onClose: @escaping OnClose.Callback = OnClose.default,
    onError: @escaping OnError.Callback = OnError.default,
    onChanged: @escaping OnChanged.Callback = OnChanged.default
  ) {
    self.onCreate = onCreate
    self.onLoaded = onLoaded
    self.onExport = onExport
    self.onUpload = onUpload
    self.onClose = onClose
    self.onError = onError
    self.onChanged = onChanged
  }
}

@_spi(Internal) public struct EngineConfiguration {
  @_spi(Internal) public let settings: EngineSettings
  @_spi(Internal) public let callbacks: EngineCallbacks
}
