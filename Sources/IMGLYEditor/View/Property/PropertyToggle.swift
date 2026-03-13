@_spi(Internal) import IMGLYCore
import IMGLYEngine
import SwiftUI

struct PropertyToggle: View {
  let label: LocalizedStringResource
  let property: Property
  let selection: Interactor.BlockID?
  let defaultValue: Bool
  let assetContext: EffectProperty.AssetContext?

  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id
  @State private var assetValue: Bool

  init(
    label: LocalizedStringResource,
    property: Property,
    selection: Interactor.BlockID? = nil,
    defaultValue: Bool,
    assetContext: EffectProperty.AssetContext? = nil
  ) {
    self.label = label
    self.property = property
    self.selection = selection
    self.defaultValue = defaultValue
    self.assetContext = assetContext
    if let assetContext, case let .boolean(_, value, _) = assetContext.assetProperty {
      _assetValue = State(initialValue: value)
    } else {
      _assetValue = State(initialValue: defaultValue)
    }
  }

  var body: some View {
    if assetContext != nil {
      assetPropertyBody
    } else {
      enginePropertyBody
    }
  }

  private var enginePropertyBody: some View {
    let binding: Binding<Bool> = interactor.bind(
      selection ?? id,
      property: property,
      default: defaultValue,
    )
    return Toggle(isOn: binding) {
      Text(label)
    }
    .tint(.accentColor)
  }

  private var assetPropertyBody: some View {
    Toggle(isOn: $assetValue) {
      Text(label)
    }
    .tint(.accentColor)
    .onChange(of: assetValue) { newValue in
      applyAssetProperty(value: newValue)
    }
  }

  private func applyAssetProperty(value: Bool) {
    guard let engine = interactor.engine,
          let assetContext,
          case let .boolean(property, _, defaultValue) = assetContext.assetProperty else { return }
    let updatedProperty = AssetProperty.boolean(
      property: property, value: value, defaultValue: defaultValue,
    )
    Task {
      do {
        try await engine.asset.applyAssetSourceProperty(
          sourceID: assetContext.sourceID,
          assetResult: assetContext.assetResult,
          property: updatedProperty,
        )
        interactor.addUndoStep()
      } catch {}
    }
  }
}
