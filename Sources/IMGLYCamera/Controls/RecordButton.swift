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
              // Video mode pre-tints the shutter; photo mode stays white.
              let useRecordingColor = state == .recording || camera.isVideoModeActive
              let videoModeInset: Double = camera.isVideoModeActive ? 16 : 0
              let isRecordingState = [.recording, .countingDown].contains(state)
              let maxWidth = isRecordingState
                ? width / 2 + padding
                : width - padding * 2 - videoModeInset
              RoundedRectangle(cornerRadius: isRecordingState ? cornerRadius : geometry.size.width / 2)
                .rotation(.degrees(isRecordingState ? 0 : -45))
                .fill(useRecordingColor ? camera.configuration.recordingColor : .white)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: maxWidth)
                .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 2)
                .animation(.imgly.growShrinkQuick, value: state)
                .animation(.easeInOut(duration: 0.2), value: useRecordingColor)
                .animation(.easeInOut(duration: 0.2), value: camera.isVideoModeActive)
            }
          }
      }
      .background {
        // A growing circle as visual feedback on tap / hold. Suppressed in photo mode.
        if camera.isVideoModeActive {
          Circle()
            .fill(camera.configuration.recordingColor)
            .opacity(isPressed ? 0.8 : 0)
            .scaleEffect(isPressed ? 1.8 : 1)
            .animation(.easeInOut(duration: isPressed ? longPressTimeout : 0.2), value: isPressed)
        }
      }
      .buttonStyle(
        ShortLongPressButtonStyle(
          longPressTimeout: longPressTimeout,
          isPressed: $isPressed,
          onShortPress: {
            guard !isTemporarilyDisabled else { return }
            camera.shutterTapped()
            disableTemporarily()
            HapticsHelper.shared.cameraStartRecording()
          },
          onLongPress: {
            camera.shutterLongPressed()
            HapticsHelper.shared.cameraStartRecording()
          },
          onLongPressRelease: {
            camera.shutterLongPressReleased()
            disableTemporarily()
            HapticsHelper.shared.cameraStopRecording()
          },
        ),
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
