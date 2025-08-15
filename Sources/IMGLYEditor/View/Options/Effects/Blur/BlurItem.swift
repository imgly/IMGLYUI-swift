@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct BlurItem: View {
  let asset: AssetLoader.Asset
  @Binding var selection: AssetSelection?
  @Binding var sheetState: EffectSheetState

  var body: some View {
    let identifier = asset.result.blurType
    let selected = selection?.identifier == identifier
    var properties: [EffectProperty] = []
    if let blurType = selection?.identifier, let blur = Interactor.BlurType(rawValue: blurType) {
      properties = EffectProperty.properties(for: blur, and: selection?.id)
    }

    return SelectableAssetItem(content: {
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
          identifier: identifier
        )
      }
    }, title: asset.result.label ?? "", selected: selected, properties: properties, asset: asset,
    sheetState: $sheetState)
  }
}
