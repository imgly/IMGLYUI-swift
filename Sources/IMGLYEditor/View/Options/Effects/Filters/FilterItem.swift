@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

/// Builds the synthetic identifier used to match duotone filter selections against assets in the
/// merged `ly.img.filter` source. Centralised so every call site normalizes colors the same way —
/// colors arrive both from engine state (`CGColor.hex()`) and from asset metadata, and may be
/// uppercase or lowercase depending on the manifest.
enum DuotoneFilterID {
  static func make(lightColor: String, darkColor: String) -> String {
    "ly.filter.duotone.\(lightColor.lowercased()).\(darkColor.lowercased())"
  }
}

struct FilterItem: View {
  let asset: AssetLoader.Asset
  @Binding var selection: AssetSelection?
  @Binding var sheetState: EffectSheetState

  var body: some View {
    let selected = selection?.identifier == identifier
    let properties = EffectProperty.properties(for: isDuotone ? .duoTone : .lut, and: selection?.id)

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
          sourceID: asset.sourceID,
        )
      }
    }, title: asset.result.label ?? "", selected: selected, properties: properties, asset: asset,
    sheetState: $sheetState)
  }

  // Duotone assets in the merged `ly.img.filter` source carry `lightColor` / `darkColor` metadata;
  // LUT assets don't.
  private var isDuotone: Bool {
    asset.result.meta?["lightColor"] != nil && asset.result.meta?["darkColor"] != nil
  }

  private var identifier: String? {
    if let lightColor = asset.result.meta?["lightColor"], let darkColor = asset.result.meta?["darkColor"] {
      return DuotoneFilterID.make(lightColor: lightColor, darkColor: darkColor)
    }
    // Use asset.id for LUT filters — matches the filterId stored in the engine.
    return asset.result.id
  }
}
