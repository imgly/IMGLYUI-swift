import CoreMedia
import SwiftUI
@_spi(Internal) import IMGLYCore

struct TimecodeView: View {
  var isRecording: Bool
  var recordedDuration: CMTime
  var maxDuration: CMTime
  var recordingColor: Color

  var body: some View {
    HStack(spacing: 3) {
      if isRecording {
        Image(systemName: "circle.fill")
          .foregroundColor(recordingColor)
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

#Preview("Recording") {
  ZStack {
    TimecodeView(
      isRecording: true,
      recordedDuration: CMTime(seconds: 10),
      maxDuration: CMTime(seconds: 30),
      recordingColor: .red
    )
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(LinearGradient(colors: [.yellow, .green], startPoint: .top, endPoint: .bottom))
  .environment(\.colorScheme, .dark)
}

#Preview("Not Recording") {
  ZStack {
    TimecodeView(
      isRecording: false,
      recordedDuration: CMTime(seconds: 10),
      maxDuration: CMTime(seconds: 30),
      recordingColor: .red
    )
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(LinearGradient(colors: [.yellow, .green], startPoint: .top, endPoint: .bottom))
  .environment(\.colorScheme, .dark)
}
