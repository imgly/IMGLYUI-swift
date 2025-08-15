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
      query: .init(query: nil, page: 0, locale: "en", perPage: 1000)
    ).assets.map {
      .init(sourceID: sourceID, result: $0)
    }

    let unregisteredFonts = assets.compactMap {
      if let url = $0.result.payload?.typeface?.previewFont?.uri, FontImporter.registeredFonts[url] == nil {
        url
      } else {
        nil
      }
    }
    let previewFontData = await Self.loadFontData(urls: unregisteredFonts)
    _ = FontImporter.importFonts(previewFontData)
  }

  private static func loadFontData(urls: [URL]) async -> [URL: Data] {
    await withThrowingTaskGroup(of: (URL, Data).self) { group -> [URL: Data] in
      for url in urls {
        group.addTask {
          let (data, _) = try await URLSession.shared.data(from: url)
          return (url, data)
        }
      }

      var downloads = [URL: Data]()

      while let result = await group.nextResult() {
        if let download = try? result.get() {
          downloads[download.0] = download.1
        }
      }

      return downloads
    }
  }
}
