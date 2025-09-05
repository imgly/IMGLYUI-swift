import IMGLYEngine
import SwiftUI
@_spi(Internal) import IMGLYCore

struct ImageItem: View {
  @EnvironmentObject private var interactor: AnyAssetLibraryInteractor

  let asset: AssetItem

  private var isVideo: Bool {
    guard case let .asset(asset) = asset else { return false }
    return asset.result.fillType == FillType.video.rawValue
  }

  var body: some View {
    switch asset {
    case let .asset(asset):
      ReloadableAsyncImage(asset: asset) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(minWidth: 0, minHeight: 0)
          .clipped()
          .aspectRatio(1, contentMode: .fit)
          .cornerRadius(8)
          .overlay(alignment: .bottomLeading) {
            if isVideo, let duration = asset.result.duration {
              VideoDurationOverlay(duration: duration)
            }
          }
      } onTap: {
        interactor.assetTapped(sourceID: asset.sourceID, asset: asset.result)
      }
    case .placeholder:
      GridItemBackground()
        .aspectRatio(1, contentMode: .fit)
    }
  }
}

struct ImageItem_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
