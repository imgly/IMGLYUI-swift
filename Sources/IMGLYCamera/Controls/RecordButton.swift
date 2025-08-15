import CoreMedia
import SwiftUI

/// The button to start and stop the recording.
struct RecordButton: View {
  @Environment(\.isEnabled) var isEnabled: Bool
  @EnvironmentObject var camera: CameraModel

  @State private var isPressed = false
  @State private var isLongPressed = false
  @State private var isTemporarilyDisabled = false

  private let longPressTimeout: TimeInterval = 0.6

  @ScaledMetric private var padding: Double = 5
  @ScaledMetric private var cornerRadius: Double = 8

  var body: some View {
    GeometryReader { geometry in
      Button {
        // The short press and long press actions are handled in the button style.
      } label: {
        let state = camera.state

        RecordingSegmentsView()
          .overlay {
            // The circle transform into a square stop shape while recording
            if isEnabled {
              let width = geometry.size.width
              RoundedRectangle(
                cornerRadius: [.recording, .countingDown].contains(state) ? cornerRadius : geometry.size.width / 2
              )
              .rotation(.degrees([.recording, .countingDown].contains(state) ? 0 : -45))
              .fill(state == .recording ? camera.configuration.recordingColor : .white)
              .aspectRatio(1, contentMode: .fit)
              .frame(maxWidth: [.recording, .countingDown].contains(state) ? width / 2 + padding : width - padding * 2)
              .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 2)
              .animation(.imgly.growShrinkQuick, value: state)
            }
          }
      }
      .background {
        // A growing circle as visual feedback on tap / hold
        Circle()
          .fill(camera.configuration.recordingColor)
          .opacity(isPressed ? 0.8 : 0)
          .scaleEffect(isPressed ? 1.8 : 1)
          .animation(.easeInOut(duration: isPressed ? longPressTimeout : 0.2), value: isPressed)
      }
      .buttonStyle(
        ShortLongPressButtonStyle(
          longPressTimeout: longPressTimeout,
          isPressed: $isPressed,
          onShortPress: {
            guard !isTemporarilyDisabled else { return }
            camera.toggleRecording()
            disableTemporarily()
            HapticsHelper.shared.cameraStartRecording()
          },
          onLongPress: {
            camera.startRecording()
            HapticsHelper.shared.cameraStartRecording()
          },
          onLongPressRelease: {
            camera.stopRecording()
            disableTemporarily()
            HapticsHelper.shared.cameraStopRecording()
          }
        )
      )
    }
  }

  /// Prevent accidential double taps.
  private func disableTemporarily() {
    guard !isTemporarilyDisabled else { return }
    isTemporarilyDisabled = true
    Task {
      try? await Task.sleep(for: .milliseconds(200))
      isTemporarilyDisabled = false
    }
  }
}
