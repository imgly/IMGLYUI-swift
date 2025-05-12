import SwiftUI

struct TextComponentItem: View {
  let asset: AssetItem

  var body: some View {
    StickerItem(asset: asset)
  }
}

struct TextComponentItem_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
