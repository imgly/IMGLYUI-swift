import SwiftUI
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI

struct FontSheet: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id
  @Environment(\.imglyFontFamilies) private var fontFamilies
  private var fontLibrary: FontLibrary { interactor.fontLibrary }

  var assets: [AssetLoader.Asset] {
    if let fontFamilies {
      fontFamilies.compactMap {
        fontLibrary.assetFor(typefaceName: $0)
      }
    } else {
      fontLibrary.assets
    }
  }

  var body: some View {
    let text = interactor.bindTextState(id, resetFontProperties: true, overrideScopes: [.key(.textCharacter)])

    DismissableBottomSheet {
      ListPicker(data: [assets], selection: text.assetID) { asset, isSelected in
        Label(asset.labelOrTypefaceName ?? "Unnamed Typeface", systemImage: "checkmark")
          .labelStyle(.icon(hidden: !isSelected,
                            titleFont: .custom(asset.result.payload?.typeface?.previewFontName ?? "", size: 17)))
      }
    }
  }
}

struct FontSheet_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews(sheet: .init(.font(nil, nil), .font))
  }
}
