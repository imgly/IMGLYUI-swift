import IMGLYCore
import SwiftUI

/// A grid of sticker assets.
public struct StickerGrid: View {
  /// Creates a grid of sticker assets.
  public init() {}

  public var body: some View {
    AssetGrid { asset in
      StickerItem(asset: asset)
    }
    .imgly.assetGrid(axis: .vertical)
    .imgly.assetGrid(items: [GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 4)])
    .imgly.assetGrid(spacing: 4)
    .imgly.assetGrid(padding: 4)
    .imgly.assetGridPlaceholderCount { state, _ in
      state == .loading ? 4 : 0
    }
    .imgly.assetLoader()
  }
}

struct StickerGrid_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
