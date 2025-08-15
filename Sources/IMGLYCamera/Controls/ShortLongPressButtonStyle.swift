import SwiftUI

/// A button style that handles taps and long press start/end events.
struct ShortLongPressButtonStyle: ButtonStyle, @unchecked Sendable {
  let longPressTimeout: TimeInterval

  @Binding var isPressed: Bool
  @State var longPressTimer: Timer?

  let onShortPress: () -> Void
  let onLongPress: () -> Void
  let onLongPressRelease: () -> Void

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .onChange(of: configuration.isPressed) { newValue in
        if isPressed == true, newValue == false, longPressTimer != nil {
          longPressTimer?.invalidate()
          longPressTimer = nil

          isPressed = false
          onShortPress()
        } else if isPressed == false, newValue == true {
          isPressed = true
          let timer = Timer(timeInterval: 0.6, repeats: false, block: { _ in
            longPressTimer = nil
            isPressed = false
            onLongPress()
          })
          longPressTimer = timer
          RunLoop.main.add(timer, forMode: .common)
        } else {
          isPressed = false
          onLongPressRelease()
        }
      }
  }
}
