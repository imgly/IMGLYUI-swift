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
    let (data, contentType) = try await export(engine)
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("Export", conformingTo: contentType)
    try data.write(to: url, options: [.atomic])
    eventHandler.send(.shareFile(url))
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

struct EngineCallbacks: Sendable {
  let onCreate: OnCreate.Callback
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

struct EngineConfiguration: Sendable {
  let settings: EngineSettings
  let callbacks: EngineCallbacks
}
