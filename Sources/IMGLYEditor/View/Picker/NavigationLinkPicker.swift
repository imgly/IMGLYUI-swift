import SwiftUI

/// Custom view that looks like `.pickerStyle(.navigationLink)` but allows to keep the picker open and explore different
/// selections.
struct NavigationLinkPicker<Data, ElementLabel: View, LinkLabel: View>: View where
  Data: RandomAccessCollection,
  Data.Element: Identifiable {
  let title: LocalizedStringKey
  let data: Data
  @Binding var selection: Data.Element.ID?

  @ViewBuilder let elementLabel: (_ element: Data.Element, _ isSelected: Bool) -> ElementLabel
  @ViewBuilder let linkLabel: (_ selection: Data.Element?) -> LinkLabel

  private func isSelecetd(_ element: Data.Element) -> Bool { selection == element.id }

  var body: some View {
    NavigationLink {
      ListPicker(data: data, selection: $selection, elementLabel: elementLabel)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationTitle(title)
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            SheetDismissButton()
              .buttonStyle(.borderless)
          }
        }
    } label: {
      HStack {
        Text(title)
        Spacer()
        linkLabel(data.first(where: isSelecetd))
          .foregroundColor(.accentColor)
          .lineLimit(1)
      }
    }
    .accessibilityLabel(title)
  }
}

struct NavigationLinkPicker_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews(sheet: .init(.layer, .text))
  }
}
