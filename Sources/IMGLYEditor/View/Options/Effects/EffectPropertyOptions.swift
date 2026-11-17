@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct EffectPropertyOptions: View {
  let title: String
  let properties: [EffectProperty]
  let backTitle: LocalizedStringResource
  var previousStyle: SheetStyle = .only(detent: .imgly.tiny)

  @Binding var sheetState: EffectSheetState
  @EnvironmentObject private var interactor: Interactor

  private func controlID(for property: EffectProperty) -> AnyHashable? {
    guard property.assetContext != nil else { return nil }
    return interactor.historyVersion
  }

  var body: some View {
    List {
      ForEach(properties, id: \.property) { property in
        propertyRow(for: property)
      }
    }
    .navigationTitle(title)
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button {
          Task {
            sheetState = .selection
            interactor.sheet.commit { model in
              model.style = previousStyle
            }
          }
        } label: {
          NavigationLabel(backTitle, direction: .backward)
        }
      }
    }
  }

  @ViewBuilder
  private func propertyRow(for property: EffectProperty) -> some View {
    switch property.value {
    case let .float(range, defaultValue):
      floatPropertyRow(property: property, range: range, defaultValue: defaultValue)
    case let .double(range, defaultValue):
      Section {
        PropertySlider(
          property.label,
          in: range,
          property: property.property,
          selection: property.id,
          defaultValue: defaultValue,
          assetContext: property.assetContext,
          // Animation properties declare ranges inside ±1 that are not
          // percentages, so the heuristic would fabricate one.
          disableAutoPercentage: true,
        )
        .id(controlID(for: property))
      } header: {
        Text(property.label)
      }
    case let .color(supportsOpacity, defaultValue):
      Section {
        PropertyColorPicker(
          property.label,
          supportsOpacity: supportsOpacity,
          property: property.property,
          selection: property.id,
          defaultValue: defaultValue,
        )
      }
    case let .boolean(defaultValue):
      Section {
        PropertyToggle(
          label: property.label,
          property: property.property,
          selection: property.id,
          defaultValue: defaultValue,
          assetContext: property.assetContext,
        )
        .id(controlID(for: property))
      }
    case let .enum(options, defaultValue):
      PropertyEnumPicker(
        label: property.label,
        options: options,
        property: property.property,
        selection: property.id,
        defaultValue: defaultValue,
        assetContext: property.assetContext,
      )
      .id(controlID(for: property))
    }
  }

  /// Routes a `.float` property to the control declared by
  /// ``EffectProperty/controlKind``, instead of always using a slider.
  @ViewBuilder
  private func floatPropertyRow(
    property: EffectProperty, range: ClosedRange<Float>, defaultValue: Float?,
  ) -> some View {
    switch property.controlKind {
    case let .slider(step):
      Section {
        PropertySlider(
          property.label,
          in: range,
          step: step,
          property: property.property,
          selection: property.id,
          defaultValue: defaultValue,
          assetContext: property.assetContext,
        )
        .id(controlID(for: property))
      } header: {
        Text(property.label)
      }
    case let .stepper(step):
      Section {
        PropertyStepper(
          property.label,
          in: range,
          step: step,
          property: property.property,
          selection: property.id,
          defaultValue: defaultValue,
        )
        .id(controlID(for: property))
      }
    }
  }
}
