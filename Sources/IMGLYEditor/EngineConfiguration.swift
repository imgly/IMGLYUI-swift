import Foundation
import UniformTypeIdentifiers
@_spi(Internal) import struct IMGLYCore.Error
import IMGLYEngine

// MARK: - Callbacks

/// A namespace for `onCreate` callbacks.
public enum OnCreate {
  /// The callback type.
  public typealias Callback = @Sendable @MainActor (_ engine: Engine) async throws -> Void

  /// The default callback which creates a new scene and loads the default and demo asset sources.
  public static let `default`: Callback = { engine in
    try engine.scene.create()
    try await loadAssetSources(engine)
  }

  /// Creates a callback that loads a scene and the default and demo asset sources.
  /// - Parameter url: The URL of the scene file.
  /// - Returns: The callback.
  public static func loadScene(from url: URL) -> Callback {
    { engine in
      try await engine.scene.load(from: url)
      try await loadAssetSources(engine)
    }
  }

  /// A callback that loads the default and demo asset sources.
  public static let loadAssetSources: Callback = { engine in
    async let loadDefault: () = engine.addDefaultAssetSources()
    async let loadDemo: () = engine.addDemoAssetSources(sceneMode: engine.scene.getMode(),
                                                        withUploadAssetSources: true)
    _ = try await (loadDefault, loadDemo)
    try await engine.asset.addSource(TextAssetSource(engine: engine))
  }
}

/// A namespace for `onExport` callbacks.
public enum OnExport {
  /// The callback type.
  public typealias Callback = @Sendable @MainActor (_ engine: Engine, _ eventHandler: EditorEventHandler) async throws
    -> Void

  /// The default callback which calls `BlockAPI.export` or `BlockAPI.exportVideo`
  /// based on the engine's `SceneMode`, displays a progress indicator for video exports, writes the content into a
  /// temporary file, and opens a system dialog for sharing the exported file.
  public static let `default`: Callback = { engine, eventHandler in
    try await `default`()(engine, eventHandler)
  }

  /// Creates the default callback which calls `BlockAPI.export` or `BlockAPI.exportVideo`
  /// based on the engine's `SceneMode`, displays a progress indicator for video exports, writes the content into a
  /// temporary file, and opens a system dialog for sharing the exported file.
  /// - Parameter mimeType: Optional mime type of the export. If `nil` the default is used based on the `SceneMode`.
  /// - Returns: The callback.
  public static func `default`(mimeType: MIMEType? = nil) -> Callback {
    { engine, eventHandler in
      let data: Data, contentType: UTType
      switch try engine.scene.getMode() {
      case .design: (data, contentType) = try await export(engine, mimeType: mimeType)
      case .video: (data, contentType) = try await exportVideo(engine, eventHandler, mimeType: mimeType)
      @unknown default:
        throw Error(errorDescription: "Unknown scene mode.")
      }
      let url = FileManager.default.temporaryDirectory.appendingPathComponent("Export", conformingTo: contentType)
      try data.write(to: url, options: [.atomic])
      switch try engine.scene.getMode() {
      case .design: eventHandler.send(.shareFile(url))
      case .video: eventHandler.send(.exportCompleted { eventHandler.send(.shareFile(url)) })
      @unknown default:
        throw Error(errorDescription: "Unknown scene mode.")
      }
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
      throw Error(errorDescription: "No scene found.")
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
  /// - Returns: The exported data and type.
  @MainActor
  public static func exportVideo(_ engine: Engine, _ eventHandler: EditorEventHandler,
                                 mimeType: MIMEType? = nil) async throws -> (Data, UTType) {
    guard let page = try engine.scene.getCurrentPage() else {
      throw Error(errorDescription: "No page found.")
    }
    eventHandler.send(.exportProgress(.relative(0)))
    let mimeType = mimeType ?? .mp4
    let stream = try await engine.block.exportVideo(page, mimeType: mimeType) { _ in }

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
    throw Error(errorDescription: "Could not export.")
  }
}

/// A namespace for `onUpload` callbacks.
public enum OnUpload {
  /// The callback type.
  public typealias Callback = @Sendable @MainActor (
    _ engine: Engine,
    _ sourceID: String,
    _ asset: AssetDefinition
  ) async throws -> AssetDefinition

  /// The default callback which forwards the unmodified `AssetDefinition`.
  public static let `default`: Callback = { _, _, asset in
    asset
  }
}

/// A namespace for `onClose` callbacks.
public enum OnClose {
  /// The callback type.
  public typealias Callback = @Sendable @MainActor (
    _ engine: Engine,
    _ eventHandler: EditorEventHandler
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
  public typealias Callback = @Sendable @MainActor (
    _ error: Swift.Error,
    _ eventHandler: EditorEventHandler
  ) -> Void

  /// The default callback that displays the error alert.
  public static let `default`: Callback = { error, eventHandler in
    eventHandler.send(.showErrorAlert(error))
  }
}

/// A namespace for `onLoaded` callbacks.
@_spi(Internal) public enum OnLoaded {
  /// The callback type.
  @_spi(Internal) public typealias Callback = @Sendable @MainActor (_ context: OnLoaded.Context) async throws
    -> Void

  /// The default empty callback.
  @_spi(Internal) public static let `default`: Callback = { _ in }

  /// The context of the ``OnLoaded/Callback``.
  @_spi(Internal) public struct Context {
    /// The engine of the current editor.
    @_spi(Internal) public let engine: Engine
    /// The event handler of the current editor.
    @_spi(Internal) public let eventHandler: EditorEventHandler
    /// The asset library configured with the ``IMGLY/assetLibrary(_:)`` view modifier.
    @_spi(Internal) public let assetLibrary: any AssetLibrary
  }
}

// MARK: - Internal interface

@_spi(Internal) public struct EngineCallbacks: Sendable {
  @_spi(Internal) public let onCreate: OnCreate.Callback
  let onLoaded: OnLoaded.Callback
  let onExport: OnExport.Callback
  let onUpload: OnUpload.Callback
  let onClose: OnClose.Callback
  let onError: OnError.Callback

  init(
    onCreate: @escaping OnCreate.Callback = OnCreate.default,
    onLoaded: @escaping OnLoaded.Callback = OnLoaded.default,
    onExport: @escaping OnExport.Callback = OnExport.default,
    onUpload: @escaping OnUpload.Callback = OnUpload.default,
    onClose: @escaping OnClose.Callback = OnClose.default,
    onError: @escaping OnError.Callback = OnError.default
  ) {
    self.onCreate = onCreate
    self.onLoaded = onLoaded
    self.onExport = onExport
    self.onUpload = onUpload
    self.onClose = onClose
    self.onError = onError
  }
}

@_spi(Internal) public struct EngineConfiguration: Sendable {
  @_spi(Internal) public let settings: EngineSettings
  @_spi(Internal) public let callbacks: EngineCallbacks
}
