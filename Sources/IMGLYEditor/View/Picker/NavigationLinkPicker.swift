import SwiftUI

/// Custom view that looks like `.pickerStyle(.navigationLink)` but allows to keep the picker open and explore different
/// selections.
struct NavigationLinkPicker<Data, ElementLabel: View, LinkLabel: View>: View where
  Data: RandomAccessCollection,
  Data.Element: RandomAccessCollection & Hashable,
  Data.Element.Element: Identifiable {
  let title: LocalizedStringKey
  let data: Data
  var inlineTitle = true
  @Binding var selection: Data.Element.Element.ID?

  @ViewBuilder let elementLabel: (_ element: Data.Element.Element, _ isSelected: Bool) -> ElementLabel
  @ViewBuilder let linkLabel: (_ selection: Data.Element.Element?) -> LinkLabel

  private func isSelecetd(_ element: Data.Element.Element) -> Bool { selection == element.id }

  private var flatData: [Data.Element.Element] {
    data.flatMap { $0 }
  }

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
        if inlineTitle {
          Text(title)
        }
        Spacer()
        linkLabel(flatData.first(where: isSelecetd))
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
