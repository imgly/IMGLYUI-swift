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

    DismissableTitledSheet(.imgly.localized("ly_img_editor_postcard_sheet_font_title")) {
      ListPicker(data: [assets], selection: text.assetID) { asset, isSelected in
        FontLoader(fontURL: asset.result.payload?.typeface?.previewFont?.uri) { fontName in
          Label(asset.labelOrTypefaceName ?? "Unnamed Typeface", systemImage: "checkmark")
            .labelStyle(.icon(hidden: !isSelected, titleFont: .custom(fontName, size: 17)))
        } placeholder: {
          Label(asset.labelOrTypefaceName ?? "Unnamed Typeface", systemImage: "checkmark")
            .labelStyle(.icon(hidden: !isSelected, titleFont: .custom("", size: 17)))
        }
      }
    }
  }
}
