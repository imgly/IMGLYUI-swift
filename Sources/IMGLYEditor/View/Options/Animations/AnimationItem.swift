@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct AnimationItem: View {
  let asset: AssetLoader.Asset
  @Binding var selection: AssetSelection?
  @Binding var sheetState: EffectSheetState
  let thumbnailsBaseURL: URL?

  private var thumbnailURL: URL? {
    guard let type = asset.result.meta?["type"],
          let baseURL = thumbnailsBaseURL else {
      return nil
    }
    return baseURL.appendingPathComponent("\(type).png")
  }

  private var identifier: String? {
    asset.result.meta?["type"]
  }

  private var selected: Bool {
    selection?.identifier == identifier
  }

  private var localizedTitle: String {
    let engineLabel = asset.result.label ?? ""
    let assetKey = asset.result.id.components(separatedBy: "/").last ?? ""
    guard !assetKey.isEmpty else { return engineLabel }
    let resourceKey = "ly_img_editor_asset_label_\(assetKey)"
    let resource: LocalizedStringResource = .imgly.localized(String.LocalizationValue(resourceKey))
    let resolved = String(localized: resource)
    return resolved == resourceKey ? engineLabel : resolved
  }

  private var properties: [EffectProperty] {
    guard let assetProperties = asset.result.payload?.properties,
          let animationBlockID = selection?.id else {
      return []
    }
    return AnimationPropertyDefinitions.properties(
      from: assetProperties,
      sourceID: asset.sourceID,
      assetResult: asset.result,
      animationBlockID: animationBlockID,
    )
  }

  var body: some View {
    SelectableAssetItem(content: {
      ReloadableAsyncImage(url: thumbnailURL, accessibilityLabel: localizedTitle) { image in
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
          sourceID: asset.sourceID,
        )
      }
    }, title: localizedTitle, selected: selected, properties: properties, asset: asset,
    sheetState: $sheetState)
  }
}
