@_spi(Internal) import IMGLYEngine
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

final class CameraAssetsInteractor: ObservableObject, AssetLibraryInteractor {
  var engine: Engine

  init(engine: Engine) {
    self.engine = engine
  }

  var isAddingAsset: Bool {
    false
  }

  func findAssets(
    sourceID: String,
    query: IMGLYEngine.AssetQueryData
  ) async throws -> IMGLYEngine.AssetQueryResult {
    try await engine.asset.findAssets(sourceID: sourceID, query: query)
  }

  func getGroups(sourceID: String) async throws -> [String] {
    try await engine.asset.getGroups(sourceID: sourceID)
  }

  func getCredits(sourceID: String) -> IMGLYEngine.AssetCredits? {
    engine.asset.getCredits(sourceID: sourceID)
  }

  func getLicense(sourceID: String) -> IMGLYEngine.AssetLicense? {
    engine.asset.getLicense(sourceID: sourceID)
  }

  func addAsset(
    to sourceID: String,
    asset: IMGLYEngine.AssetDefinition
  ) async throws -> IMGLYEngine.AssetDefinition {
    try engine.asset.addAsset(to: sourceID, asset: asset)
    return asset
  }

  func assetTapped(sourceID _: String, asset _: IMGLYEngine.AssetResult) {}
}
