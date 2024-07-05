@_spi(Internal) import IMGLYCore
import SwiftUI

struct TextItem: View {
  @EnvironmentObject private var interactor: AnyAssetLibraryInteractor
  let asset: AssetItem

  @State var fontName: String?

  @ViewBuilder var placeholder: some View {
    GridItemBackground()
      .frame(width: 160, height: 24)
    Spacer()
  }

  var body: some View {
    HStack(spacing: 0) {
      switch asset {
      case let .asset(asset):
        FontLoader(fontURL: asset.result.url) { fontName in
          Text(asset.result.label ?? "Text")
            .font(.custom(fontName, size: asset.result.fontSize ?? 17))
          Spacer()
          Image(systemName: "plus.square.fill")
            .foregroundStyle(.secondary)
            .imageScale(.large)
        } placeholder: {
          placeholder
        }
      case .placeholder:
        placeholder
      }
    }
    .padding([.leading, .trailing], 16)
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

struct TextItem_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
