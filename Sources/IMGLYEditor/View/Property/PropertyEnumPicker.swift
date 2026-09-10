@_spi(Internal) import IMGLYCore
import IMGLYEngine
import SwiftUI

struct PropertyEnumPicker: View {
  let label: LocalizedStringResource
  let options: [EffectProperty.EnumOption]
  let property: Property
  let selection: Interactor.BlockID?
  let defaultValue: String?
  let assetContext: EffectProperty.AssetContext?

  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id
  @State private var assetValue: String

  init(
    label: LocalizedStringResource,
    options: [EffectProperty.EnumOption],
    property: Property,
    selection: Interactor.BlockID? = nil,
    defaultValue: String?,
    assetContext: EffectProperty.AssetContext? = nil
  ) {
    self.label = label
    self.options = options
    self.property = property
    self.selection = selection
    self.defaultValue = defaultValue
    self.assetContext = assetContext
    if let assetContext, case let .enum(_, value, _, _) = assetContext.assetProperty {
      _assetValue = State(initialValue: value)
    } else {
      _assetValue = State(initialValue: defaultValue ?? options.first?.id ?? "")
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
    let binding: Binding<String> = interactor.bind(
      selection ?? id,
      property: property,
      default: defaultValue ?? "",
    )
    return Section {
      Picker(selection: binding) {
        ForEach(options) { option in
          Text(option.label).tag(option.id)
        }
      } label: {
        Text(label)
      }
    }
  }

  // MARK: - Asset Property Body

  private var assetPropertyBody: some View {
    Section {
      Picker(selection: $assetValue) {
        ForEach(options) { option in
          Text(option.label).tag(option.id)
        }
      } label: {
        Text(label)
      }
      .onChange(of: assetValue) { newValue in
        applyAssetProperty(value: newValue)
      }
    }
  }

  // MARK: - Apply

  private func applyAssetProperty(value: String) {
    guard let engine = interactor.engine,
          let assetContext,
          case let .enum(property, _, defaultValue, options) = assetContext.assetProperty else { return }
    let updatedProperty = AssetProperty.enum(
      property: property, value: value, defaultValue: defaultValue,
      options: options,
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
