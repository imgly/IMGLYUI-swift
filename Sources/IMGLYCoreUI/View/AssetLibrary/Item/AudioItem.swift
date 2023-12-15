@_spi(Internal) import IMGLYCore
import SwiftUI

struct AudioItem: View {
  @EnvironmentObject private var interactor: AnyAssetLibraryInteractor
  let asset: AssetItem

  func duration(asset: AssetLoader.Asset) -> String? {
    guard let duration = asset.result.duration else {
      return nil
    }
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.unitsStyle = .positional
    return formatter.string(from: duration)
  }

  @ViewBuilder func titleAndArtist(asset: AssetLoader.Asset) -> some View {
    let title = asset.result.title ?? asset.result.label
    if let title, let artist = asset.result.artist {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.body)
        Text(artist)
          .font(.caption.weight(.medium))
          .foregroundStyle(.secondary)
      }
    } else {
      Text(title ?? "")
        .font(.body)
    }
  }

  var body: some View {
    HStack(spacing: 0) {
      ImageItem(asset: asset)
        .padding(.trailing, 16)
      switch asset {
      case let .asset(asset):
        titleAndArtist(asset: asset)
        Spacer(minLength: 16)
        if let duration = duration(asset: asset) {
          Text(duration)
            .font(.caption.weight(.medium).monospacedDigit())
            .foregroundStyle(.secondary)
            .padding(.trailing, 16)
        }
      case .placeholder:
        GridItemBackground()
          .frame(width: 120, height: 24)
        Spacer()
      }
    }
    .contentShape(Rectangle())
    .onTapGesture {
      guard case let .asset(asset) = asset else {
        return
      }
      interactor.assetTapped(sourceID: asset.sourceID, asset: asset.result)
    }
    .frame(height: 48)
  }
}

struct AudioItem_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
