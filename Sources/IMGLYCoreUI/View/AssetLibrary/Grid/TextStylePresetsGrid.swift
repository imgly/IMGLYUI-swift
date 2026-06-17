import IMGLYCore
import SwiftUI

/// A grid of text style-preset assets (engine source `ly.img.text.presets`).
///
/// Used as the `destination` of `AssetLibrarySource.textStylePreset(_:source:)`.
///
/// - Note: The source must be registered on the engine for content to appear.
public struct TextStylePresetsGrid: View {
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

public extension TextStylePresetsGrid {
  /// Maps a style-preset asset `group` to its localized section title.
  ///
  /// The localization key is derived from the group
  /// (`ly_img_editor_asset_library_section_text_style_presets_<group>`), so a new preset group
  /// shipped with the asset content only needs its translation string. Until a translation
  /// exists, the raw group id is shown.
  static func sectionTitle(for group: String?) -> LocalizedStringResource {
    guard let group else {
      return .imgly.localized("ly_img_editor_asset_library_section_text_style_presets")
    }
    let key = "ly_img_editor_asset_library_section_text_style_presets_\(group)"
    let resource: LocalizedStringResource = .imgly.localized(String.LocalizationValue(key))
    guard String(localized: resource) == key else { return resource }
    return "\(group)"
  }
}

struct TextStylePresetsGrid_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
