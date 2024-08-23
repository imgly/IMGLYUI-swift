import Foundation
import UniformTypeIdentifiers
@_spi(Internal) import struct IMGLYCore.Error
import IMGLYEngine
import struct SwiftUI.LocalizedStringKey

/// An export progress visualization.
public enum ExportProgress {
  /// Show spinner.
  case spinner
  /// Show relative progress for given percentage value.
  case relative(_ percentage: Float)
}

/// An editor event that can be sent via `EditorEventHandler`.
public enum EditorEvent {
  /// Show share sheet for given URL.
  case shareFile(URL)
  /// Show export progress sheet for given state.
  case exportProgress(ExportProgress = .spinner)
  /// Show export completed sheet and perform given action after dismissal.
  case exportCompleted(action: () -> Void = {})
}

/// An interface for sending editor events.
@MainActor
public protocol EditorEventHandler {
  /// A function for sending `EditorEvent`s.
  /// - Parameter event: The event to send.
  func send(_ event: EditorEvent)
}

// MARK: - Callbacks

/// A namespace for `onCreate` callbacks.
public enum OnCreate {
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
    for try await export in stream {
      try Task.checkCancellation()
      switch export {
      case let .progress(_, encodedFrames, totalFrames):
        let percentage = Float(encodedFrames) / Float(totalFrames)
        eventHandler.send(.exportProgress(.relative(percentage)))
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

// MARK: - Internal interface

@_spi(Internal) public struct EngineCallbacks: Sendable {
  @_spi(Internal) public let onCreate: OnCreate.Callback
  let onExport: OnExport.Callback
  let onUpload: OnUpload.Callback

  init(
    onCreate: @escaping OnCreate.Callback = OnCreate.default,
    onExport: @escaping OnExport.Callback = OnExport.default,
    onUpload: @escaping OnUpload.Callback = OnUpload.default
  ) {
    self.onCreate = onCreate
    self.onExport = onExport
    self.onUpload = onUpload
  }
}

@_spi(Internal) public struct EngineConfiguration: Sendable {
  @_spi(Internal) public let settings: EngineSettings
  @_spi(Internal) public let callbacks: EngineCallbacks
}
