import SwiftUI

struct ShapeItem: View {
  @EnvironmentObject private var interactor: AnyAssetLibraryInteractor

  let asset: AssetItem

  var body: some View {
    switch asset {
    case let .asset(asset):
      ReloadableAsyncImage(asset: asset) { image in
        image
          .resizable()
          .renderingMode(.template)
          .foregroundColor(.primary)
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

struct ShapeItem_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
