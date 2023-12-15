import SwiftUI

struct SelectableItem<Content: View>: View {
  let title: LocalizedStringKey
  let selected: Bool
  @ViewBuilder let content: Content

  var body: some View {
    VStack(spacing: 3) {
      content
        .cornerRadius(8)
        .frame(width: 80, height: 80)
        .padding(3)
        .overlay {
          RoundedRectangle(cornerRadius: 10)
            .stroke(Color.accentColor, lineWidth: 2)
            .opacity(selected ? 1 : 0)
        }
      Text(title)
        .font(.caption2)
    }
    .accessibilityLabel(title)
  }
}
