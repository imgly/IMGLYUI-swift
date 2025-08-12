@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct FilterOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  let getter: Interactor.RawGetter<AssetSelection> = { engine, block in
    let effects = try? engine.block.getEffects(block)
    if let filter = effects?.first(where: { effect in
      let type = try? engine.block.getType(effect)
      return type?.isFilter ?? false
    }) {
      if let sourceURL: String = try? engine.block.get(filter, property: .key(.filterLUTFileURI)) {
        return AssetSelection(identifier: sourceURL, assetURL: sourceURL, id: filter)
      } else if let lightColor: CGColor = try? engine.block.get(filter, property: .key(.filterDuoToneLightColor)),
                let darkColor: CGColor = try? engine.block.get(filter, property: .key(.filterDuoToneDarkColor)),
                let lightHex = try? lightColor.hex(),
                let darkHex = try? darkColor.hex() {
        return AssetSelection(identifier: "ly.filter.duotone.\(lightHex).\(darkHex)", id: filter)
      }
      return AssetSelection()
    }
    return AssetSelection()
  }

  let setter: Interactor.RawSetter<AssetSelection> = { engine, blocks, value, completion in
    @MainActor func createLUT(
      _ id: Interactor.BlockID,
      source: String,
      index: Int? = nil,
    ) throws {
      if let index {
        try engine.block.removeEffect(id, index: index)
      }
      let filter = try engine.block.createEffect(.lutFilter)
      try engine.block.set(filter, property: .key(.filterLUTFileURI), value: source)
      let horizontalTileCount = Int(value.metadata?[.horizontalTileCount] ?? "5") ?? 5
      let verticalTileCount = Int(value.metadata?[.verticalTileCount] ?? "5") ?? 5
      try engine.block.set(filter, property: .key(.filterLUTHorizontalTileCount), value: horizontalTileCount)
      try engine.block.set(filter, property: .key(.filterLUTVerticalTileCount), value: verticalTileCount)
      try engine.block.set(filter, property: .key(.filterLUTIntensity), value: 1.0)
      try engine.block.appendEffect(id, effectID: filter)
    }

    @MainActor func createDuoTone(_ id: Interactor.BlockID, index: Int? = nil) throws {
      if let index {
        try engine.block.removeEffect(id, index: index)
      }
      let filter = try engine.block.createEffect(.duotoneFilter)
      guard let lightHex = value.metadata?[.lightColor],
            let darkHex = value.metadata?[.darkColor],
            let lightColor = CGColor.imgly.hex(lightHex),
            let darkColor = CGColor.imgly.hex(darkHex) else {
        throw Error(errorDescription: "Could not retrieve colors for DuoTone filter.")
      }
      try engine.block.set(filter, property: .key(.filterDuoToneLightColor), value: lightColor)
      try engine.block.set(filter, property: .key(.filterDuoToneDarkColor), value: darkColor)
      try engine.block.set(filter, property: .key(.filterDuoToneIntensity), value: 0.0)
      try engine.block.appendEffect(id, effectID: filter)
    }

    try blocks.forEach { block in
      let effects = try? engine.block.getEffects(block)

      if value.identifier != nil {
        var index: Int?
        if let filter = effects?.first(where: { effect in
          let type = try? engine.block.getType(effect)
          return type?.isFilter ?? false
        }) {
          index = effects?.firstIndex(of: filter)
        }
        if let source = value.assetURL {
          try createLUT(block, source: source, index: index)
        } else {
          try createDuoTone(block, index: index)
        }
      } else {
        let filters = effects?.filter {
          let type = try? engine.block.getType($0)
          return type?.isFilter ?? false
        }
        try filters?.forEach { filter in
          if let index = effects?.firstIndex(of: filter) {
            try engine.block.removeEffect(block, index: index)
          }
        }
      }
    }
    return try (completion?(engine, blocks, true) ?? true)
  }

  var body: some View {
    let selection = interactor.bind(id, getter: getter, setter: setter)
    EffectOptions(
      selection: selection,
      item: { asset, binding in FilterItem(asset: asset, selection: selection, sheetState: binding) },
      identifier: { identifier(for: $0) },
      sources: [.init(id: "ly.img.filter.duotone"), .init(id: "ly.img.filter.lut")],
    )
  }

  private func identifier(for asset: AssetLoader.Asset) -> String? {
    if asset.sourceID == "ly.img.filter.duotone" {
      guard let lightColor = asset.result.meta?[.lightColor],
            let darkColor = asset.result.meta?[.darkColor]
      else {
        return nil
      }
      return "ly.filter.duotone.\(lightColor).\(darkColor)"
    } else {
      return asset.result.url?.absoluteString
    }
  }
}

// MARK: - Private Extensions

private enum AssetSelectionMetaKey: String {
  case lightColor
  case darkColor
  case horizontalTileCount
  case verticalTileCount
}

private extension [String: String] {
  subscript(_ key: AssetSelectionMetaKey) -> Value? {
    self[key.rawValue]
  }
}

private extension String {
  var isFilter: Bool {
    hasSuffix("lut_filter") || hasSuffix("duotone_filter")
  }
}
