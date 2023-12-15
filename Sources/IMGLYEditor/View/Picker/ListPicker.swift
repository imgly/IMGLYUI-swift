import SwiftUI

struct ListPicker<Data, ElementLabel: View>: View where
  Data: RandomAccessCollection,
  Data.Element: Identifiable {
  let data: Data
  @Binding var selection: Data.Element.ID?

  @ViewBuilder let elementLabel: (_ element: Data.Element, _ isSelected: Bool) -> ElementLabel

  private func isSelecetd(_ element: Data.Element) -> Bool { selection == element.id }

  var body: some View {
    ScrollViewReader { proxy in
      List(data) { element in
        Button {
          selection = element.id
        } label: {
          let isSelected = isSelecetd(element)
          elementLabel(element, isSelected)
            .foregroundColor(isSelected ? .accentColor : .primary)
        }
        .id(element.id)
      }
      .safeAreaInset(edge: .top) { Color.clear.frame(height: 15) }
      .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 15) }
      .task {
        proxy.scrollTo(selection, anchor: .center)
      }
      .onChange(of: selection) { newValue in
        withAnimation {
          proxy.scrollTo(newValue)
        }
      }
    }
  }
}
