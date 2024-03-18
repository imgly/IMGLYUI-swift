import SwiftUI

/// A custom style for the icon buttons.
struct CameraToolButtonStyle: ButtonStyle {
  @ScaledMetric private var minWidth: Double = 44

  func makeBody(configuration: Configuration) -> some View {
    HStack {
      configuration.label
        .font(.title2)
        .fontWeight(.medium)
        .frame(minWidth: minWidth)
        .frame(minHeight: minWidth)
    }
    .contentShape(Rectangle())
    .foregroundColor(.white)
    .opacity(configuration.isPressed ? 0.6 : 1)
    .shadow(color: .black.opacity(0.3), radius: 1.5, x: 0, y: 1)
    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 4)
    .background {
      HStack {
        if configuration.isPressed {
          Circle()
            .fill(.gray.opacity(0.2))
            .padding(-10)
            .transition(.scale.combined(with: .opacity))
        }
      }
      .animation(configuration.isPressed
        ? nil
        : .imgly.growShrinkSlow.delay(0.25), value: configuration.isPressed)
    }
  }
}
