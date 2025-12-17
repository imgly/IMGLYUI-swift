import Foundation
@_spi(Internal) import IMGLYCore
import IMGLYEngine

@MainActor
class AssetLibraryInteractorMock: ObservableObject {
  @Published private(set) var isAddingAsset = false
  @Published private(set) var sceneMode: SceneMode?

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
      let basePath = "https://cdn.img.ly/packages/imgly/cesdk-engine/1.66.0/assets"
      try engine.editor.setSettingString("basePath", value: basePath)
      async let loadDefault: () = engine.addDefaultAssetSources()
      async let loadDemo: () = engine.addDemoAssetSources(sceneMode: engine.scene.getMode(),
                                                          withUploadAssetSources: true)
      _ = try await (loadDefault, loadDemo)
      try await engine.asset.addSource(TextAssetSource(engine: engine))
      try engine.asset.addSource(PhotoRollAssetSource(engine: engine))
      sceneMode = try engine.scene.getMode()
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
