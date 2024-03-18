import SwiftUI

/// A button that toggles between two states but allows more styling control than a SwiftUI `Toggle`.
struct ToggleButton: View {
  @State var isEnabled: Bool
  let icon: Image
  let disabledIcon: Image
  var highlightBackground = false
  var changeCallback: () -> Void
  var body: some View {
    Toggle(isOn: $isEnabled) {
      (isEnabled ? icon : disabledIcon)
        .foregroundColor(isEnabled && highlightBackground ? .accentColor : .primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
    .toggleStyle(.button)
    .buttonStyle(.plain)
    .frame(width: 34, height: 34)
    .background {
      if isEnabled, highlightBackground {
        RoundedRectangle(cornerRadius: 6)
          .fill(isEnabled ? Color.accentColor : .primary)
          .opacity(0.1)
      }
    }
    .animation(.linear(duration: 0.2), value: isEnabled)
    .onChange(of: isEnabled) { _ in
      changeCallback()
    }
  }
}
