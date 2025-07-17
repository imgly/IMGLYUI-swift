import CoreMedia
import SwiftUI
@_spi(Internal) import IMGLYCore

struct TimecodeView: View {
  @EnvironmentObject var camera: CameraModel
  @EnvironmentObject var recordingsManager: RecordingsManager

  var maxDuration: CMTime {
    camera.reactionVideoDuration ?? camera.configuration.maxTotalDuration
  }

  var body: some View {
    let isRecording = camera.state == .recording
    let recordedDuration = recordingsManager
      .recordedClipsTotalDuration + (recordingsManager.currentlyRecordedClipDuration ?? .zero)

    HStack(spacing: 3) {
      if isRecording {
        Image(systemName: "circle.fill")
          .foregroundColor(camera.configuration.recordingColor)
          .transition(.scale)
      }

      Text(recordedDuration.imgly.formattedDurationStringForPlayer())
        .foregroundStyle(.white)

      if maxDuration < .positiveInfinity {
        Text("/")
          .foregroundStyle(.white.opacity(0.6))
        Text(maxDuration.imgly.formattedDurationStringForPlayer())
          .foregroundStyle(.white)
          .opacity(0.7)
      }
    }
    .monospacedDigit()
    .font(.callout)
    .fontWeight(.medium)
    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 4)
    .padding(.trailing, 10)
    .padding(.vertical, 4)
    .padding(.leading, isRecording ? 4 : 10)
    .background {
      RoundedRectangle(cornerRadius: .infinity, style: .circular)
        .fill(.ultraThinMaterial)
    }
    .fixedSize()
    .animation(.imgly.growShrinkQuick, value: isRecording)
  }
}

struct TimecodeView_Previews: PreviewProvider {
  static var previews: some View {
    TimecodeView()
      .environmentObject(CameraModel(.init(license: ""), onDismiss: .modern { _ in }))
  }
}
