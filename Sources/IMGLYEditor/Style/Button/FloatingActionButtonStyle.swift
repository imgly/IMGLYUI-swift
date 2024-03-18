import SwiftUI

struct FloatingActionButtonStyle: PrimitiveButtonStyle {
  @Environment(\.colorScheme) private var colorScheme

  func makeBody(configuration: Configuration) -> some View {
    Button(configuration)
      .foregroundColor(.accentColor)
      .background(
        Circle()
          .fill(Color.accentColor)
          .opacity(0.25)
          .shadow(color: .black.opacity(0.1), radius: 4, y: 1)
          .background {
            Circle()
              .fill(.background)
              .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 2)
          }
          .overlay {
            Circle()
              .inset(by: 0.25)
              .stroke(Color.accentColor, lineWidth: 0.5)
              .opacity(colorScheme == .light ? 0.16 : 0.25)
          }
      )
  }
}
