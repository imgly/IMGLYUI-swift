import Foundation
@_spi(Internal) import IMGLYCore
import IMGLYEngine

@MainActor
class AssetLibraryInteractorMock: ObservableObject {
  @Published private(set) var isAddingAsset = false
  private var engine: Engine?
  private var sceneTask: Task<Void, Swift.Error>?

  func loadScene() {
    guard sceneTask == nil else {
      return
    }
    sceneTask = Task {
      let request = PreviewServerRequest.secrets.url()
      let (data, _) = try await URLSession.shared.data(from: request)
      let secrets = try JSONDecoder().decode(Secrets.self, from: data)

      let engine = try await Engine(license: secrets.licenseKey)
      self.engine = engine
      try engine.scene.createVideo()
      let baseURL = URL(string: "https://cdn.img.ly/packages/imgly/cesdk-swift/1.77.1/assets")!
      try engine.editor.setSettingString("basePath", value: baseURL.absoluteString)
      let defaultSourceIDs = [
        "ly.img.sticker", "ly.img.vector.shape", "ly.img.filter", "ly.img.color.palette",
        "ly.img.effect", "ly.img.blur", "ly.img.typeface", "ly.img.crop.presets",
        "ly.img.page.presets", "ly.img.text", "ly.img.text.styles", "ly.img.text.curves",
        "ly.img.text.components", "ly.img.caption.presets",
      ]
      let remoteDemoSourceIDs = ["ly.img.image", "ly.img.audio", "ly.img.video"]
      let uploadDemoSources: [(id: String, mimeTypes: [String])] = [
        ("ly.img.image.upload", ["image/jpeg", "image/png", "image/svg+xml", "image/gif", "image/apng", "image/bmp"]),
        ("ly.img.audio.upload", ["audio/x-m4a", "audio/mp3", "audio/mpeg"]),
        ("ly.img.video.upload", ["video/mp4"]),
      ]
      for id in defaultSourceIDs + remoteDemoSourceIDs {
        _ = try await engine.asset.addLocalAssetSourceFromJSON(
          baseURL.appendingPathComponent(id).appendingPathComponent("content.json"),
        )
      }
      for source in uploadDemoSources {
        try engine.asset.addLocalSource(sourceID: source.id, supportedMimeTypes: source.mimeTypes)
      }
      try engine.asset.addSource(PhotoRollAssetSource(engine: engine))
    }
  }
}

extension AssetLibraryInteractorMock: AssetLibraryInteractor {
  func findAssets(sourceID: String, query: IMGLYEngine.AssetQueryData) async throws -> IMGLYEngine.AssetQueryResult {
    loadScene()
    _ = await sceneTask?.result
    guard let engine else { throw Error(errorDescription: "Engine unavailable.") }
    return try await engine.asset.findAssets(sourceID: sourceID, query: query)
  }

  func getGroups(sourceID: String) async throws -> [String] {
    loadScene()
    _ = await sceneTask?.result
    guard let engine else { throw Error(errorDescription: "Engine unavailable.") }
    return try await engine.asset.getGroups(sourceID: sourceID)
  }

  func getCredits(sourceID: String) -> AssetCredits? {
    guard let engine else { return nil }
    return engine.asset.getCredits(sourceID: sourceID)
  }

  func getLicense(sourceID: String) -> AssetLicense? {
    guard let engine else { return nil }
    return engine.asset.getLicense(sourceID: sourceID)
  }

  func addAsset(to sourceID: String, asset: IMGLYEngine.AssetDefinition) async throws -> AssetDefinition {
    guard let engine else { throw Error(errorDescription: "Engine unavailable.") }
    try engine.asset.addAsset(to: sourceID, asset: asset)
    return asset
  }

  func assetTapped(sourceID _: String, asset _: IMGLYEngine.AssetResult) {
    isAddingAsset = true
    Task {
      try await Task.sleep(nanoseconds: NSEC_PER_SEC)
      isAddingAsset = false
    }
  }
}
