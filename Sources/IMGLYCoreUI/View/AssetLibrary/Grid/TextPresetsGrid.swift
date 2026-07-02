import IMGLYCore
import SwiftUI

/// A grid of text style-preset assets (engine sources `ly.img.text`, `ly.img.text.styles`, `ly.img.text.curves`).
///
/// Used as the `destination` of `AssetLibrarySource.textPreset(_:source:)`.
///
/// - Note: The source must be registered on the engine for content to appear.
public struct TextPresetsGrid: View {
  /// Creates a grid of text style-preset assets.
  public init() {}

  public var body: some View {
    AssetGrid { asset in
      StickerItem(asset: asset)
    }
    .imgly.assetGrid(axis: .vertical)
    .imgly.assetGrid(items: [GridItem(.adaptive(minimum: 108, maximum: 152), spacing: 4)])
    .imgly.assetGrid(spacing: 4)
    .imgly.assetGrid(padding: 4)
    .imgly.assetGridPlaceholderCount { state, _ in
      state == .loading ? 3 : 0
    }
    .imgly.assetLoader()
  }
}

public extension TextPresetsGrid {
  /// Maps a style-preset asset `group` to its localized section title.
  ///
  /// The localization key is `keyPrefix` + `group`, so a new preset group shipped with the asset
  /// content only needs its translation string. Until a translation exists, the raw group id is
  /// shown. When `group` is `nil`, the prefix's trailing `_` is dropped to form the base section key.
  static func sectionTitle(
    for group: String?,
    keyPrefix: String = "ly_img_editor_asset_library_section_text_style_presets_",
  ) -> LocalizedStringResource {
    guard let group else {
      let baseKey = keyPrefix.hasSuffix("_") ? String(keyPrefix.dropLast()) : keyPrefix
      return .imgly.localized(String.LocalizationValue(baseKey))
    }
    let key = "\(keyPrefix)\(group)"
    let resource: LocalizedStringResource = .imgly.localized(String.LocalizationValue(key))
    guard String(localized: resource) == key else { return resource }
    return "\(group)"
  }
}

struct TextPresetsGrid_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
