import Foundation
import UniformTypeIdentifiers
@_spi(Internal) import struct IMGLYCore.Error
import IMGLYEngine
import struct SwiftUI.LocalizedStringKey

@_exported import IMGLYCore
@_exported import IMGLYCoreUI

public enum ExportProgress {
  case spinner
  case relative(_ percentage: Float)
}

public enum EditorEvent {
  case shareFile(URL)
  case exportProgress(ExportProgress = .spinner)
  case exportCompleted(action: () -> Void = {})
}

@MainActor
public protocol EditorEventHandler {
  func send(_ event: EditorEvent)
}

// MARK: - Callbacks

public enum OnCreate {
  public typealias Callback = @Sendable @MainActor (_ engine: Engine) async throws -> Void

  public static let `default`: Callback = { engine in
    try engine.scene.create()
    try await loadAssetSources(engine)
  }

  public static func loadScene(from url: URL) -> Callback {
    { engine in
      try await engine.scene.load(from: url)
      try await loadAssetSources(engine)
    }
  }

  public static let loadAssetSources: Callback = { engine in
    async let loadDefault: () = engine.addDefaultAssetSources()
    async let loadDemo: () = engine.addDemoAssetSources(sceneMode: engine.scene.getMode(),
                                                        withUploadAssetSources: true)
    _ = try await (loadDefault, loadDemo)
    try engine.asset.addSource(TextAssetSource(engine: engine))
  }
}

public enum OnExport {
  public typealias Callback = @Sendable @MainActor (_ engine: Engine, _ eventHandler: EditorEventHandler) async throws
    -> Void

  public static let `default`: Callback = { engine, eventHandler in
    let data: Data, contentType: UTType
    switch try engine.scene.getMode() {
    case .design: (data, contentType) = try await export(engine)
    case .video: (data, contentType) = try await exportVideo(engine, eventHandler)
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

  @MainActor
  public static func export(_ engine: Engine) async throws -> (Data, UTType) {
    guard let scene = try engine.scene.get() else {
      throw Error(errorDescription: "No scene found.")
    }
    let mimeType: MIMEType = .pdf
    let data = try await engine.block.export(scene, mimeType: mimeType) { engine in
      try engine.scene.getPages().forEach {
        try engine.block.setScopeEnabled($0, key: "layer/visibility", enabled: true)
        try engine.block.setVisible($0, visible: true)
      }
    }
    return (data, mimeType.uniformType)
  }

  @MainActor
  public static func exportVideo(_ engine: Engine, _ eventHandler: EditorEventHandler) async throws -> (Data, UTType) {
    guard let page = try engine.scene.getCurrentPage() else {
      throw Error(errorDescription: "No page found.")
    }
    eventHandler.send(.exportProgress(.relative(0)))
    let mimeType: MIMEType = .mp4
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

public enum OnUpload {
  public typealias Callback = @Sendable @MainActor (
    _ engine: Engine,
    _ sourceID: String,
    _ asset: AssetDefinition
  ) async throws -> AssetDefinition

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
