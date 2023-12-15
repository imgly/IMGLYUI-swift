import SwiftUI

struct StickerItem: View {
  @EnvironmentObject private var interactor: AnyAssetLibraryInteractor

  let asset: AssetItem

  var body: some View {
    switch asset {
    case let .asset(asset):
      ReloadableAsyncImage(asset: asset) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fit)
          .aspectRatio(1, contentMode: .fit)
          .padding(8)
      } onTap: {
        interactor.assetTapped(sourceID: asset.sourceID, asset: asset.result)
      }
    case .placeholder:
      GridItemBackground()
        .aspectRatio(1, contentMode: .fit)
    }
  }
}

struct StickerItem_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
