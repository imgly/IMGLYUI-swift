import IMGLYCore
import SwiftUI

/// A grid of text component assets.
public struct TextComponentGrid: View {
  /// Creates a grid of text component assets.
  public init() {}

  public var body: some View {
    AssetGrid { asset in
      TextComponentItem(asset: asset)
    }
    .imgly.assetGrid(axis: .vertical)
    .imgly.assetGrid(items: [GridItem(.adaptive(minimum: 108, maximum: 152), spacing: 4)])
    .imgly.assetGrid(spacing: 4)
    .imgly.assetGrid(padding: 4)
    .imgly.assetGridPlaceholderCount { state, _ in
      state == .loading ? 3 : 0
    }
    .imgly.assetLoader()
  }
}

struct TextComponentGrid_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
