@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct FilterItem: View {
  let asset: AssetLoader.Asset
  @Binding var selection: AssetSelection?
  @Binding var sheetState: EffectSheetState

  typealias AssetSource = Interactor.DefaultAssetSource

  var body: some View {
    let selected = selection?.identifier == identifier
    let isLUT = asset.sourceID == AssetSource.filterLut.rawValue
    let properties = EffectProperty.properties(for: isLUT ? .lut : .duoTone, and: selection?.id)

    SelectableAssetItem(content: {
      ReloadableAsyncImage(asset: asset) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(minWidth: 0, minHeight: 0)
          .clipped()
          .aspectRatio(1, contentMode: .fit)
          .cornerRadius(8)
      } onTap: {
        selection = AssetSelection(
          identifier: identifier,
          assetURL: asset.result.url?.absoluteString,
          metadata: asset.result.meta,
          sourceID: asset.sourceID
        )
      }
    }, title: asset.result.label ?? "", selected: selected, properties: properties, asset: asset,
    sheetState: $sheetState)
  }

  private var identifier: String? {
    if asset.sourceID == AssetSource.filterLut.rawValue {
      return asset.result.url?.absoluteString
    }
    if let lightColor = asset.result.meta?["lightColor"], let darkColor = asset.result.meta?["darkColor"] {
      return "ly.filter.duotone.\(lightColor.lowercased()).\(darkColor.lowercased())"
    }
    return nil
  }
}
