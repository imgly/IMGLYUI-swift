import SwiftUI

struct DelayedGesture<T: Gesture>: ViewModifier {
  var duration: TimeInterval
  var gesture: T
  @State private var disabled = false

  func body(content: Content) -> some View {
    Button {} label: {
      content
    }
    .buttonStyle(DelayedGestureButtonStyle(duration: duration, disabled: $disabled))
    .disabled(disabled)
    .gesture(gesture)
  }
}

private struct DelayedGestureButtonStyle: ButtonStyle, @unchecked Sendable {
  var duration: TimeInterval

  @Binding var disabled: Bool
  @State private var touchDownDate: Date?

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .onChange(of: configuration.isPressed, perform: pressedChanged)
  }

  private func pressedChanged(isPressed: Bool) {
    if isPressed {
      let date = Date()
      touchDownDate = date
      DispatchQueue.main.asyncAfter(deadline: .now() + max(duration, 0)) {
        if date == touchDownDate {
          disabled = true

          DispatchQueue.main.async {
            disabled = false
          }
        }
      }
    } else {
      touchDownDate = nil
      disabled = false
    }
  }
}
