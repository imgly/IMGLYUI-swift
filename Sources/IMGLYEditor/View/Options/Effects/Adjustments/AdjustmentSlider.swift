@_spi(Internal) import IMGLYCore
import SwiftUI

struct AdjustmentSlider: View {
  let adjustment: Adjustment
  let title: LocalizedStringKey

  var body: some View {
    let property = "effect/adjustments/\(adjustment.rawValue)"
    let getter: Interactor.PropertyGetter<Float> = { engine, block, _, _ in
      let effects = try? engine.block.getEffects(block)
      if let adjustmentEffect = effects?.first(where: { effect in
        let type = try? engine.block.getType(effect)
        return type?.hasSuffix("adjustments") ?? false
      }) {
        let value = try? engine.block.getFloat(adjustmentEffect, property: property)
        return value ?? 0
      }
      return 0
    }

    let setter: Interactor.PropertySetter<Float> = { engine, blocks, _, _, value, completion in
      try blocks.forEach { block in
        let effects = try? engine.block.getEffects(block)
        if let adjustmentEffect = effects?.first(where: { effect in
          let type = try? engine.block.getType(effect)
          return type?.hasSuffix("adjustments") ?? false
        }) {
          try engine.block.setFloat(adjustmentEffect, property: property, value: value)
        } else {
          let adjustments = try engine.block.createEffect(.adjustments)
          try engine.block.appendEffect(block, effectID: adjustments)
          try engine.block.setFloat(adjustments, property: property, value: value)
        }
      }
      return try (completion?(engine, blocks, true) ?? true)
    }
    Section(title) {
      PropertySlider<Float>(.init(adjustment.rawValue), in: -1 ... 1, property: .raw(property), setter: setter,
                            getter: getter)
    }
  }
}
