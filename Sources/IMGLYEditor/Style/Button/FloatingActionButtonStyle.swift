import SwiftUI

struct FloatingActionButtonStyle: PrimitiveButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    Button(configuration)
      .foregroundColor(.white)
      .background(
        Circle()
          .fill(Color.accentColor)
          .shadow(color: .black.opacity(0.1), radius: 4, y: 1)
      )
  }
}
