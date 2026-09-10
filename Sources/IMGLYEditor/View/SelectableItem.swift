import SwiftUI

struct SelectableItem<Content: View>: View {
  let title: String
  let selected: Bool
  @ViewBuilder let content: Content

  var body: some View {
    VStack(spacing: 3) {
      content
        .cornerRadius(8)
        .padding(4)
        .overlay {
          RoundedRectangle(cornerRadius: 10)
            .inset(by: 1)
            .stroke(Color.accentColor, lineWidth: 2)
            .opacity(selected ? 1 : 0)
        }
      Text(title)
        .font(.caption2)
    }
    .accessibilityLabel(title)
  }
}
