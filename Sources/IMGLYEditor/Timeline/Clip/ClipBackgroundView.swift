import CoreMedia
import SwiftUI

/// Manages the thumbnail images or waveform for a `Clip`.
struct ClipBackgroundView: View {
  // MARK: - Properties

  @EnvironmentObject var timeline: Timeline
  @Environment(\.imglyTimelineConfiguration) var configuration: TimelineConfiguration
  @ObservedObject var thumbnailsProvider: AnyThumbnailsProvider

  private let clip: Clip
  private let cornerRadius: CGFloat
  private let pointsTrimOffsetWidth: CGFloat

  // MARK: - Initializers

  init(clip: Clip, cornerRadius: CGFloat, pointsTrimOffsetWidth: CGFloat, thumbnailsProvider: AnyThumbnailsProvider) {
    self.clip = clip
    self.cornerRadius = cornerRadius
    self.pointsTrimOffsetWidth = pointsTrimOffsetWidth
    self.thumbnailsProvider = thumbnailsProvider
  }

  // MARK: - View

  var body: some View {
    RoundedRectangle(cornerRadius: cornerRadius)
      .fill(clip.configuration.backgroundColor)
      .overlay(alignment: .bottomLeading) {
        thumbnailView
          .offset(x: pointsTrimOffsetWidth)
          .allowsHitTesting(false)
      }
      .mask {
        RoundedRectangle(cornerRadius: cornerRadius)
      }
      .clipped()
  }

  /// Returns the appropriate thumbnail view based on the provider type.
  @ViewBuilder
  private var thumbnailView: some View {
    switch thumbnailsProvider.provider {
    case let thumbnailsAudioProvider as ThumbnailsAudioProvider:
      ThumbnailsAudioView(
        provider: thumbnailsAudioProvider,
        isZooming: timeline.isPinchingZoom,
        pointsTrimOffsetWidth: pointsTrimOffsetWidth,
        color: clip.configuration.color,
      )
    case let thumbnailsImageProvider as ThumbnailsImageProvider:
      ThumbnailsImageView(
        provider: thumbnailsImageProvider,
        isZooming: timeline.isPinchingZoom,
      )
    default:
      EmptyView()
    }
  }
}
