import SwiftUI

struct ClipSpeedStepper: View {
  let isEnabled: Bool
  let previousSpeed: Float?
  let nextSpeed: Float?
  let previousSpeedProvider: () -> Float?
  let nextSpeedProvider: () -> Float?
  let onSpeedSelected: (Float) -> Void

  private var dividerColor: SwiftUI.Color {
    SwiftUI.Color(.tertiaryLabel).opacity(0.3)
  }

  var body: some View {
    HStack(spacing: 0) {
      ClipSpeedStepperButton(
        systemName: "minus",
        isEnabled: isEnabled && previousSpeed != nil,
        speedProvider: previousSpeedProvider,
        onSpeedSelected: onSpeedSelected,
      )
      ClipSpeedStepperButton(
        systemName: "plus",
        isEnabled: isEnabled && nextSpeed != nil,
        speedProvider: nextSpeedProvider,
        onSpeedSelected: onSpeedSelected,
      )
    }
    .frame(width: 94, height: ClipSpeedDefaults.inputHeight)
    .background(Color(.tertiarySystemFill))
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    .overlay {
      Rectangle()
        .fill(dividerColor)
        .frame(width: 1)
        .padding(.vertical, 7)
    }
  }
}

private struct ClipSpeedStepperButton: View {
  let systemName: String
  let isEnabled: Bool
  let speedProvider: () -> Float?
  let onSpeedSelected: (Float) -> Void

  @State private var isPressing = false
  @State private var repeatTask: Task<Void, Never>?
  @State private var didLongPress = false

  var body: some View {
    Button(action: handleTap) {
      Image(systemName: systemName)
        .font(.body)
        .foregroundStyle(isEnabled ? Color.primary : Color(.tertiaryLabel))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(!isEnabled)
    .onLongPressGesture(minimumDuration: 0.5, pressing: handlePressing, perform: {})
    .onDisappear(perform: stopRepeating)
  }

  private func handleTap() {
    guard isEnabled, !didLongPress else { return }
    _ = triggerAction()
  }

  private func handlePressing(_ pressing: Bool) {
    isPressing = pressing
    if pressing {
      startRepeating()
    } else {
      stopRepeating()
    }
  }

  private func triggerAction() -> Bool {
    guard let speed = speedProvider() else { return false }
    onSpeedSelected(speed)
    return true
  }

  private func startRepeating() {
    guard isEnabled else { return }
    stopRepeating()
    repeatTask = Task { @MainActor in
      try? await Task.sleep(nanoseconds: 500_000_000)
      guard !Task.isCancelled, isPressing, isEnabled else { return }
      didLongPress = true
      guard triggerAction() else { return }
      while !Task.isCancelled, isPressing, isEnabled {
        try? await Task.sleep(nanoseconds: 250_000_000)
        guard !Task.isCancelled, isPressing, isEnabled else { return }
        if !triggerAction() {
          stopRepeating()
          return
        }
      }
    }
  }

  private func stopRepeating() {
    repeatTask?.cancel()
    repeatTask = nil
    if didLongPress {
      didLongPress = false
    }
  }
}
