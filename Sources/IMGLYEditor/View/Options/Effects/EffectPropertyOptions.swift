import SwiftUI

struct EffectPropertyOptions: View {
  let title: LocalizedStringKey
  let properties: [EffectProperty]
  let backTitle: LocalizedStringKey

  @Binding var sheetState: EffectSheetState
  @EnvironmentObject private var interactor: Interactor

  var body: some View {
    List {
      ForEach(properties, id: \.property) { property in
        switch property.value {
        case let .float(range, defaultValue):
          Section(property.label) {
            PropertySlider(
              property.label,
              in: range,
              property: property.property,
              selection: property.id,
              defaultValue: defaultValue
            )
          }
        case let .color(supportsOpacity, defaultValue):
          Section {
            PropertyColorPicker(
              property.label,
              supportsOpacity: supportsOpacity,
              property: property.property,
              selection: property.id,
              defaultValue: defaultValue
            )
          }
        }
      }
    }
    .navigationTitle(title)
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button {
          Task {
            sheetState = .selection
            var detents: Set<PresentationDetent> = [.imgly.tiny]
            if properties.count > 1 {
              detents.insert(.imgly.medium)
            }
            interactor.sheet.commit { model in
              model = .init(model.mode, model.type, style: .only(detent: .imgly.tiny))
            }
          }
        } label: {
          NavigationLabel(backTitle, direction: .backward)
        }
      }
    }
  }
}
