import SwiftUI

/// A view that displays the audio thumbnails as a series of waveform bars.
struct ThumbnailsAudioView: View {
  /// Metrics used for configuring the appearance of the waveform bars.
  enum Metrics {
    static let minimumHeight: CGFloat = 1
    static let variableHeightPercentage: CGFloat = 0.8
    static let barWidth: CGFloat = 1
    static let barGap: CGFloat = 1
    static let minHeight: CGFloat = 1
  }

  @ObservedObject var provider: ThumbnailsAudioProvider

  let isZooming: Bool
  let pointsTrimOffsetWidth: CGFloat
  let color: Color

  var body: some View {
    HStack(spacing: Metrics.barGap) {
      ForEach(provider.audioWaves.indices, id: \.self) { index in
        WaveformBar(height: heightFor(provider.audioWaves[index]))
      }
    }
    .blur(radius: isZooming ? 10 : 0)
    .foregroundColor(color)
    .frame(height: provider.thumbHeight * Metrics.variableHeightPercentage)
    .offset(x: pointsTrimOffsetWidth)
    .padding(.vertical, 4)
    .padding(.horizontal, 1)
  }

  /// Calculates the height for a waveform bar based on the audio value.
  private func heightFor(_ audioValue: Float) -> CGFloat {
    max(CGFloat(audioValue) * Metrics.variableHeightPercentage * provider.thumbHeight, Metrics.minHeight)
  }
}

/// A view that represents a single waveform bar.
struct WaveformBar: View {
  var height: CGFloat

  var body: some View {
    WaveformShape(height: height)
      .frame(width: ThumbnailsAudioView.Metrics.barWidth, height: height)
  }
}

/// A shape that represents a single waveform bar with rounded corners.
struct WaveformShape: Shape {
  let cornerRadii = RectangleCornerRadii(topLeading: 0.5,
                                         bottomLeading: 0.5,
                                         bottomTrailing: 0.5,
                                         topTrailing: 0.5)

  var height: CGFloat

  func path(in _: CGRect) -> Path {
    var path = Path()
    path.addRoundedRect(in: CGRect(x: 0, y: 0, width: ThumbnailsAudioView.Metrics.barWidth, height: height),
                        cornerRadii: cornerRadii)
    return path
  }

  var animatableData: CGFloat {
    get { height }
    set { height = newValue }
  }
}
