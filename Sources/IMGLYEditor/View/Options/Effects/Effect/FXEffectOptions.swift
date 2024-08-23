@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct FXEffectOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  let getter: Interactor.RawGetter<AssetSelection> = { engine, block in
    let effects = try? engine.block.getEffects(block)
    if let effect = try effects?.first(where: { effect in
      let type = try engine.block.getType(effect)
      return type.isEffect
    }) {
      let type = try engine.block.getType(effect)
      return AssetSelection(identifier: type, id: effect)
    }
    return AssetSelection()
  }

  let setter: Interactor.RawSetter<AssetSelection> = { engine, blocks, value, completion in
    var didChange = false
    try blocks.forEach { block in
      let effects = try? engine.block.getEffects(block)
      if let effect = try effects?.first(where: { effect in
        let type = try engine.block.getType(effect)
        return type.isEffect
      }) {
        if let index = effects?.firstIndex(of: effect) {
          try engine.block.removeEffect(block, index: index)
          didChange = true
        }
      }
      if let newIdentifier = value.identifier, let effect = Interactor.EffectType(rawValue: newIdentifier) {
        let newEffect = try engine.block.createEffect(effect)
        try engine.block.appendEffect(block, effectID: newEffect)
        didChange = true
      }
    }
    return try (completion?(engine, blocks, didChange) ?? false) || didChange
  }

  var body: some View {
    let selection = interactor.bind(id, getter: getter, setter: setter)
    EffectOptions(
      selection: selection,
      item: { asset, binding in
        FXEffectItem(asset: asset, selection: selection, sheetState: binding)
      },
      identifier: { $0.result.effectType },
      sources: [.init(id: "ly.img.effect")]
    )
  }
}

private extension String {
  var isEffect: Bool {
    if let effect = Interactor.EffectType(rawValue: self) {
      let permitted: [Interactor.EffectType] = [
        .adjustments,
        .lutFilter,
        .duotoneFilter,
      ]
      return !permitted.contains(effect)
    }
    return false
  }
}
