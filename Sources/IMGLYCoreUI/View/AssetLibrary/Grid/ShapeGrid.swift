import IMGLYCore
import SwiftUI

public struct ShapeGrid: View {
  public init() {}

  public var body: some View {
    AssetGrid { asset in
      ShapeItem(asset: asset)
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

struct ShapeGrid_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
