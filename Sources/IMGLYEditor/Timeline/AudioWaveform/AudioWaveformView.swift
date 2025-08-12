import CoreMedia
import SwiftUI

/// Mock audio waveform visualization.
struct AudioWaveformView: View {
  let zoomLevel: CGFloat

  let width: CGFloat
  let height: CGFloat

  private let barWidth: CGFloat = 1
  private let barGap: CGFloat = 1

  var body: some View {
    GeometryReader { geometry in
      let count = Int(geometry.size.width / (barWidth + barGap))
      let waveformZoom = zoomLevel * 0.25 + 1
      HStack(spacing: barGap) {
        ForEach(0 ... count, id: \.self) { index in
          let height = abs(sin(Double(index) / waveformZoom)) * height * 0.7 + height * 0.3
          RoundedRectangle(cornerRadius: 0.5)
            .frame(
              width: barWidth,
              height: height,
            )
        }
      }
    }
    .frame(width: width)
  }
}

struct AudioWaveformView_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      AudioWaveformView(zoomLevel: 1, width: 100, height: 20)
      AudioWaveformView(zoomLevel: 1, width: 100, height: 20)
        .frame(height: 20)
      AudioWaveformView(zoomLevel: 3, width: 100, height: 20)
        .frame(height: 20)
    }
  }
}
