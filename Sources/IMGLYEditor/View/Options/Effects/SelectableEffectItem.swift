import SwiftUI

struct SelectableEffectItem<Content: View>: View {
  let title: LocalizedStringKey
  let selected: Bool
  @ViewBuilder let content: Content

  var body: some View {
    SelectableItem(title: title, selected: selected) {
      content
        .frame(width: 80, height: 80)
    }
  }
}
