import CoreMedia
@_spi(Internal) import IMGLYCore
import SwiftUI

/// A label with automatic formatting for metadata in a `Clip`.
struct ClipLabelView: View {
  let duration: CMTime?
  let icon: Image?
  let title: String
  let isMuted: Bool
  let isSelectable: Bool
  let cornerRadius: CGFloat

  // The height thresholds between which the opacity interpolates from hidden to visible
  @ScaledMetric private var minThreshold = 16
  @ScaledMetric private var maxThreshold = 20

  var body: some View {
    if duration != nil || isMuted || icon != nil || !title.isEmpty {
      HStack(spacing: 2) {
        HStack(spacing: 2) {
          if let duration {
            Text(duration.imgly.formattedDurationStringForClip())
              .fixedSize()
          }
          if isMuted {
            Image(systemName: "speaker.slash.fill")
              .font(.caption)
          }
          if !isSelectable {
            Image(systemName: "lock")
              .font(.caption)
          } else if let icon {
            icon
          }
          Text(title)
            .lineLimit(1)
        }
        .monospacedDigit()
        .padding(.horizontal, 5)
        .padding(.vertical, 1)
        .background {
          RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.ultraThinMaterial)
        }
      }
      .font(.footnote)
      .padding(2)
      .foregroundColor(isSelectable ? .primary : .secondary)
    }
  }
}

struct ClipLabelView_Previews: PreviewProvider {
  static var previews: some View {
    VStack(alignment: .leading) {
      ClipLabelView(duration: CMTime(seconds: 20),
                    icon: Image(systemName: "video"),
                    title: "Video",
                    isMuted: true,
                    isSelectable: true,
                    cornerRadius: 8)
      ClipLabelView(duration: CMTime(seconds: 1.5),
                    icon: Image(systemName: "music.note"),
                    title: "Audio",
                    isMuted: false,
                    isSelectable: false,
                    cornerRadius: 8)
    }
  }
}
