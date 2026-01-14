import SwiftUI
@_spi(Internal) import IMGLYCoreUI
import IMGLYEngine

class FontLibrary {
  private(set) var assets: [AssetLoader.Asset] = []

  func assetFor(typefaceName: String) -> AssetLoader.Asset? {
    assets.first { $0.result.payload?.typeface?.name == typefaceName }
  }

  private func assetFor(id: String) -> AssetLoader.Asset? {
    assets.first { $0.id == id }
  }

  func typefaceFor(id: String) -> Typeface? {
    assetFor(id: id)?.result.payload?.typeface
  }

  @MainActor
  func loadFromAssetSource(engine: Engine, sourceID: String) async throws {
    assets = try await engine.asset.findAssets(
      sourceID: sourceID,
      query: .init(query: nil, page: 0, locale: "en", perPage: 1000),
    ).assets.map {
      .init(sourceID: sourceID, result: $0)
    }
  }
}
