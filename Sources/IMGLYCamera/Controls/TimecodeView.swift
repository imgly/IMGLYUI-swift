import CoreMedia
import SwiftUI
@_spi(Internal) import IMGLYCore

struct TimecodeView: View {
  @EnvironmentObject var camera: CameraModel
  @EnvironmentObject var recordingsManager: RecordingsManager

  var body: some View {
    let isRecording = camera.state == .recording
    let recordedDuration = recordingsManager
      .recordedClipsTotalDuration + (recordingsManager.currentlyRecordedClipDuration ?? .zero)

    HStack(spacing: 6) {
      if isRecording {
        Image(systemName: "circle.fill")
          .foregroundColor(camera.configuration.recordingColor)
          .transition(.scale)
      }

      Text(recordedDuration.imgly.formattedDurationStringForPlayer())
        .foregroundStyle(.white)

      if camera.configuration.maxTotalDuration < .positiveInfinity {
        Text("/")
          .foregroundStyle(.white.opacity(0.6))
        Text(camera.configuration.maxTotalDuration.imgly.formattedDurationStringForPlayer())
          .foregroundStyle(.white)
      }
    }
    .monospacedDigit()
    .font(.callout)
    .fontWeight(.medium)
    .shadow(color: .black.opacity(0.5), radius: 1.5, x: 0, y: 1)
    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 4)
    .padding(.trailing, 10)
    .padding(.vertical, 4)
    .padding(.leading, isRecording ? 6 : 10)
    .background {
      RoundedRectangle(cornerRadius: .infinity)
        .fill(.ultraThinMaterial)
    }
    .fixedSize()
    .animation(.imgly.growShrinkQuick, value: isRecording)
  }
}

struct TimecodeView_Previews: PreviewProvider {
  static var previews: some View {
    TimecodeView()
      .environmentObject(CameraModel(.init(license: "")) { _ in })
  }
}
