import CoreMedia
import SwiftUI

/// Manages the thumbnail images or waveform for a `Clip`.
struct ClipBackgroundView: View {
  @EnvironmentObject var timeline: Timeline
  @Environment(\.imglyTimelineConfiguration) var configuration: TimelineConfiguration

  @ObservedObject var thumbnailsProvider: ThumbnailsProvider

  let clip: Clip
  let cornerRadius: CGFloat

  private let pointsTrimOffsetWidth: CGFloat
  private let maxWaveformHeight: CGFloat = 20

  init(clip: Clip, cornerRadius: CGFloat, pointsTrimOffsetWidth: CGFloat, thumbnailsProvider: ThumbnailsProvider) {
    self.clip = clip
    self.cornerRadius = cornerRadius
    self.pointsTrimOffsetWidth = pointsTrimOffsetWidth
    self.thumbnailsProvider = thumbnailsProvider
  }

  var body: some View {
    RoundedRectangle(cornerRadius: cornerRadius)
      .fill(clip.configuration.backgroundColor)
      .overlay(alignment: .bottomLeading) {
        // We could remove GeometryReader so that the clip doesn’t expand invisibly horizontally.
        if clip.clipType == .audio {
          GeometryReader { geometry in
            AudioWaveformView(
              zoomLevel: timeline.zoomLevel,
              width: geometry.size.width + abs(pointsTrimOffsetWidth),
              height: geometry.size.height
            )
            .foregroundColor(clip.configuration.color)
            .frame(maxHeight: maxWaveformHeight)
            .offset(x: pointsTrimOffsetWidth)
            // Prevent animation glitch on expand/collapse timeline.
            .drawingGroup()
          }
          .frame(maxHeight: maxWaveformHeight)
          .padding(.vertical, 4)
          .padding(.horizontal, 1)
        } else {
          ThumbnailsView(
            provider: thumbnailsProvider,
            isZooming: timeline.isPinchingZoom
          )
          .offset(x: pointsTrimOffsetWidth)
          .allowsHitTesting(false)
        }
      }
      .mask {
        RoundedRectangle(cornerRadius: cornerRadius)
      }
      .clipped()
  }
}
