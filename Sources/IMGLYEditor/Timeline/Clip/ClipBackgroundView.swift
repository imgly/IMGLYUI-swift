import CoreMedia
import SwiftUI

/// Manages the thumbnail images or waveform for a `Clip`.
struct ClipBackgroundView: View {
  // MARK: - Properties

  @EnvironmentObject var timeline: Timeline
  @Environment(\.imglyTimelineConfiguration) var configuration: TimelineConfiguration
  @Environment(\.colorScheme) private var colorScheme
  @ObservedObject var thumbnailsProvider: AnyThumbnailsProvider

  private let clip: Clip
  private let cornerRadius: CGFloat
  private let pointsTrimOffsetWidth: CGFloat
  private let labelWidth: CGFloat

  // MARK: - Initializers

  init(
    clip: Clip,
    cornerRadius: CGFloat,
    pointsTrimOffsetWidth: CGFloat,
    thumbnailsProvider: AnyThumbnailsProvider,
    labelWidth: CGFloat = 0
  ) {
    self.clip = clip
    self.cornerRadius = cornerRadius
    self.pointsTrimOffsetWidth = pointsTrimOffsetWidth
    self.thumbnailsProvider = thumbnailsProvider
    self.labelWidth = labelWidth
  }

  // MARK: - View

  private var backgroundStyle: AnyShapeStyle {
    switch clip.clipType {
    case .audio, .voiceOver:
      return AnyShapeStyle(clip.configuration.backgroundColor)
    default:
      let colors: [Color] = colorScheme == .dark
        ? [Color(uiColor: .systemFill), Color(uiColor: .quaternarySystemFill)]
        : [Color(uiColor: .quaternarySystemFill), Color(uiColor: .systemFill)]
      return AnyShapeStyle(.linearGradient(.init(colors: colors), startPoint: .top, endPoint: .bottom))
    }
  }

  var body: some View {
    RoundedRectangle(cornerRadius: cornerRadius)
      .fill(backgroundStyle)
      .overlay(alignment: .bottomLeading) {
        thumbnailView
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
    case let provider as ThumbnailsAudioProvider:
      // Audio needs additional offset to stay at its loaded time position.
      // Outer offset (pointsTrimOffsetWidth) is already applied, so we add the difference.
      let loadedTrimOffsetPoints = timeline.convertToPoints(time: provider.loadedTrimOffset)
      let currentTrimOffsetPoints = timeline.convertToPoints(time: clip.trimOffset)
      let audioOffset = loadedTrimOffsetPoints - currentTrimOffsetPoints + pointsTrimOffsetWidth
      ThumbnailsAudioView(
        provider: provider,
        isZooming: timeline.isPinchingZoom,
        color: clip.configuration.color,
      )
      .offset(x: audioOffset)
    case let provider as ThumbnailsTextProvider:
      ThumbnailsTextView(
        provider: provider,
        isZooming: timeline.isPinchingZoom,
        labelWidth: labelWidth,
      )
    case let provider as ThumbnailsImageProvider:
      ThumbnailsImageView(
        provider: provider,
        isZooming: timeline.isPinchingZoom,
        labelWidth: labelWidth,
        trimOffset: pointsTrimOffsetWidth,
      )
      .offset(x: pointsTrimOffsetWidth)
    default:
      EmptyView()
    }
  }
}
