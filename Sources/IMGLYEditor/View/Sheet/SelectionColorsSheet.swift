import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct SelectionColorsSheet: View {
  @EnvironmentObject private var interactor: Interactor

  @State var selectionColors = SelectionColors()

  @ViewBuilder func colorOptions(_ title: LocalizedStringKey, colors: [SelectionColor]) -> some View {
    ForEach(colors) { color in
      ColorOptions(title: title, color: color.binding, addUndoStep: interactor.addUndoStep)
    }
  }

  var body: some View {
    BottomSheet {
      List {
        let sections = interactor.bind(selectionColors, completion: nil)
        ForEach(sections, id: \.name) { section in
          if section.name.isEmpty {
            Section {
              colorOptions("Template Color", colors: section.colors)
            }
          } else {
            let title = LocalizedStringKey(section.name)
            Section(title) {
              colorOptions(LocalizedStringKey(section.name + " Color"), colors: section.colors)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(title)
          }
        }
      }
      .labelStyle(.iconOnly)
      .buttonStyle(.borderless)
    }
    .onAppear {
      selectionColors = interactor.selectionColors
    }
  }
}

struct SelectionColorsSheet_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews(sheet: .init(.selectionColors, .selectionColors))
  }
}
