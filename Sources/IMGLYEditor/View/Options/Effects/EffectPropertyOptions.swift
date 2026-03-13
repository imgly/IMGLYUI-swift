import SwiftUI

struct EffectPropertyOptions: View {
  let title: String
  let properties: [EffectProperty]
  let backTitle: LocalizedStringResource

  @Binding var sheetState: EffectSheetState
  @EnvironmentObject private var interactor: Interactor

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
            )
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
              model.style = .only(detent: .imgly.tiny)
            }
          }
        } label: {
          NavigationLabel(backTitle, direction: .backward)
        }
      }
    }
  }
}
