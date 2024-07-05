import SwiftUI

struct ListPicker<Data, ElementLabel: View>: View where
  Data: RandomAccessCollection,
  Data.Element: RandomAccessCollection & Hashable,
  Data.Element.Element: Identifiable {
  let data: Data
  @Binding var selection: Data.Element.Element.ID?

  @ViewBuilder let elementLabel: (_ element: Data.Element.Element, _ isSelected: Bool) -> ElementLabel

  private func isSelecetd(_ element: Data.Element.Element) -> Bool { selection == element.id }

  var body: some View {
    ScrollViewReader { proxy in
      List(data, id: \.sectionId) { element in
        Section {
          ForEach(element) { item in
            Button {
              selection = item.id
            } label: {
              let isSelected = isSelecetd(item)
              elementLabel(item, isSelected)
                .foregroundColor(isSelected ? .accentColor : .primary)
            }
            .id(item.id)
          }
        }
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

private extension RandomAccessCollection where Self: Hashable, Element: Identifiable {
  var sectionId: Int {
    map(\.id).hashValue
  }
}
