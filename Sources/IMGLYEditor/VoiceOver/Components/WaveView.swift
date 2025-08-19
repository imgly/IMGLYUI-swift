import SwiftUI

// View responsible for displaying an individual wave form segment.
struct WaveView: View {
  // MARK: - Constants

  private enum Colors {
    static var waveRecording: Color { Color.pink }
    static var wave: Color { Color.primary }
  }

  // MARK: - Properties

  @ObservedObject var wave: Wave
  let maxHeight: CGFloat

  private var height: CGFloat {
    max(CGFloat(wave.value) * maxHeight, 1)
  }

  var body: some View {
    let waveRect = CGRect(
      x: CGFloat(wave.position) * (VoiceOverConfiguration.waveSizeWidth + VoiceOverConfiguration.waveSpaceSizeWidth),
      y: (maxHeight - height) / 2,
      width: VoiceOverConfiguration.waveSizeWidth,
      height: height,
    )
    let color = wave.recorded ? Colors.waveRecording : Colors.wave
    return Path(waveRect)
      .fill(color)
  }
}
