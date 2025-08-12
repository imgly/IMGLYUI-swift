import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct SelectionColorsSheet: View {
  @EnvironmentObject private var interactor: Interactor

  @State var selectionColors = SelectionColors()

  @ViewBuilder func colorOptions(_ title: LocalizedStringResource, colors: [SelectionColor]) -> some View {
    ForEach(colors) { color in
      ColorOptions(title: title, color: color.binding, addUndoStep: interactor.addUndoStep)
    }
  }

  var body: some View {
    DismissableTitledSheet(.imgly.localized("ly_img_editor_postcard_sheet_colors_title")) {
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
              colorOptions(
                "ly_img_editor_postcard_sheet_template_colors_color_picker_title \(section.name)",
                colors: section.colors,
              )
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
