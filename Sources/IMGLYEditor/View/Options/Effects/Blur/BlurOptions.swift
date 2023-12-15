@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct BlurOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  let getter: Interactor.RawGetter<AssetSelection> = { engine, block in
    if let currentBlur = try? engine.block.getBlur(block), let type = try? engine.block.getType(currentBlur) {
      return AssetSelection(identifier: type, id: currentBlur)
    }
    return AssetSelection()
  }

  let setter: Interactor.RawSetter<AssetSelection> = { engine, blocks, value, completion in
    var hasChanges = false
    try blocks.forEach { block in
      if let blur = try? engine.block.getBlur(block), engine.block.isValid(blur) {
        try engine.block.overrideAndRestore(blur, scope: .key(.lifecycleDestroy)) { id in
          try engine.block.destroy(id)
        }
        hasChanges = true
      }
      if let newIdentifier = value.identifier, let blur = Interactor.BlurType(rawValue: newIdentifier) {
        let newBlur = try engine.block.createBlur(blur)
        try engine.block.setBlur(block, blurID: newBlur)
        hasChanges = true
      }
    }
    return try (completion?(engine, blocks, hasChanges) ?? false) || hasChanges
  }

  var body: some View {
    let selection = interactor.bind(id, getter: getter, setter: setter)
    EffectOptions(
      selection: selection,
      item: { asset, binding in
        BlurItem(asset: asset, selection: selection, sheetState: binding)
      },
      identifier: { $0.result.blurType },
      sources: [.init(id: "ly.img.blur")]
    )
  }
}
