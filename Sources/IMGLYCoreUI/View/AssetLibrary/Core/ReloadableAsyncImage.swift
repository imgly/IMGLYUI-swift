import IMGLYCore
import IMGLYEngine
import Kingfisher
import SwiftUI

@_spi(Internal) public struct ReloadableAsyncImage<Content: View>: View {
  let asset: AssetLoader.Asset
  @ViewBuilder let content: (KFImage) -> Content
  let onTap: () -> Void

  @_spi(Internal) public init(asset: AssetLoader.Asset, content: @escaping (KFImage) -> Content,
                              onTap: @escaping () -> Void) {
    self.asset = asset
    self.content = content
    self.onTap = onTap
  }

  @State private var state = LoadingState.loading

  @ViewBuilder private var background: some View {
    GridItemBackground()
      .aspectRatio(1, contentMode: .fit)
  }

  private enum LoadingState {
    case loading, error, loaded
  }

  @_spi(Internal) public var body: some View {
    ZStack {
      switch state {
      case .loading:
        background
          .imgly.shimmer()
      case .error:
        background
          .overlay {
            Image("custom.photo.badge.exclamationmark", bundle: .module)
              .imageScale(.large)
              .foregroundColor(.secondary)
          }
      case .loaded:
        background
      }

      if state != .error {
        Button {
          onTap()
        } label: {
          content(
            KFImage(asset.thumbURLorURL)
              .retry(maxCount: 3)
              .onSuccess { _ in
                state = .loaded
              }
              .onFailure { _ in
                state = .error
              }
              .fade(duration: 0.15)
          )
        }
        .allowsHitTesting(state == .loaded)
        .accessibilityLabel(asset.result.label ?? "")
      }
    }
  }
}

struct ReloadableAsyncImage_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
