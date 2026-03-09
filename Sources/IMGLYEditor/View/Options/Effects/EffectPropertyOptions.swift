@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct EffectPropertyOptions: View {
  let title: String
  let properties: [EffectProperty]
  let backTitle: LocalizedStringResource
  var previousDetent: PresentationDetent = .imgly.tiny

  @Binding var sheetState: EffectSheetState
  @EnvironmentObject private var interactor: Interactor

  private func controlID(for property: EffectProperty) -> AnyHashable? {
    guard property.assetContext != nil else { return nil }
    return interactor.historyVersion
  }

  var body: some View {
    List {
      ForEach(properties, id: \.property) { property in
        switch property.value {
        case let .float(range, defaultValue):
          Section {
            PropertySlider(
              property.label,
              in: range,
              property: property.property,
              selection: property.id,
              defaultValue: defaultValue,
              assetContext: property.assetContext,
            )
            .id(controlID(for: property))
          } header: {
            Text(property.label)
          }
        case let .double(range, defaultValue):
          Section {
            PropertySlider(
              property.label,
              in: range,
              property: property.property,
              selection: property.id,
              defaultValue: defaultValue,
              assetContext: property.assetContext,
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
          PropertyToggle(
            label: property.label,
            property: property.property,
            selection: property.id,
            defaultValue: defaultValue,
            assetContext: property.assetContext,
          )
          .id(controlID(for: property))
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
    }
    .navigationTitle(title)
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button {
          Task {
            sheetState = .selection
            interactor.sheet.commit { model in
              model.style = .only(detent: previousDetent)
            }
          }
        } label: {
          NavigationLabel(backTitle, direction: .backward)
        }
      }
    }
  }
}
