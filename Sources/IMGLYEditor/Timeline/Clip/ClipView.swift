import CoreMedia
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

/// A `ClipView` that is displayed in the `TimelineView`.
struct ClipView: View {
  @EnvironmentObject var timeline: Timeline
  @EnvironmentObject var timelineProperties: TimelineProperties
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.imglyTimelineConfiguration) var configuration: TimelineConfiguration

  @ObservedObject private(set) var clip: Clip
  private let isSelected: Bool

  @State private var pointsDurationWidth: CGFloat = 0
  @State private var pointsTimeOffsetWidth: CGFloat = 0
  @State private var pointsTrimOffsetWidth: CGFloat = 0

  private let clipSpacing: CGFloat

  init(clip: Clip, isSelected: Bool, clipSpacing: CGFloat) {
    self.clip = clip
    self.isSelected = isSelected
    self.clipSpacing = clipSpacing
  }

  var body: some View {
    let cornerRadius = configuration.cornerRadius
    RoundedRectangle(cornerRadius: cornerRadius)
      .fill(Color.clear)
      .background(alignment: .bottomLeading) {}
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius - 2).inset(by: clip.clipType != .audio ? 0 : 1))
      .background {
        if let thumbnailsProvider = try? timelineProperties.thumbnailsManager.getProvider(id: clip.id) {
          ClipBackgroundView(
            clip: clip,
            cornerRadius: cornerRadius,
            pointsTrimOffsetWidth: 0,
            thumbnailsProvider: thumbnailsProvider
          )
          .overlay {
            RoundedRectangle(cornerRadius: cornerRadius - 1)
              .inset(by: 0.25)
              .strokeBorder(
                clip.configuration.color.opacity(0.25),
                style: clip.allowsSelecting
                  ? SwiftUI.StrokeStyle(lineWidth: 0.5)
                  : SwiftUI.StrokeStyle(lineWidth: 0.5, dash: [2], dashPhase: 4)
              )
          }
          .opacity(isSelected ? 0 : 1)
          .modifier(Shimmering(isShimmering: clip.isLoading))
        }
      }
      .opacity(clip.allowsSelecting ? 1 : 0.3)
      .overlay(alignment: .topLeading) {
        if !isSelected {
          ClipLabelView(
            duration: nil,
            icon: clip.configuration.icon,
            title: clip.title,
            isMuted: clip.audioVolume == 0 || clip.isMuted,
            isSelectable: clip.allowsSelecting,
            cornerRadius: cornerRadius - 2
          )
        }
      }
      .clipped()
      .contentShape(Rectangle())
      // We put the spacing between clips *inside* the clip bounds
      // to make time calculations easier.
      // We don’t show the gap when the clip is selected.
      .padding(.trailing, isSelected ? 0 : clipSpacing)
      .frame(width: pointsDurationWidth)

      // Dimming overlay where clip exceeds total duration
      .overlay(alignment: .trailing) {
        let overflow = timeline.totalWidth - pointsTimeOffsetWidth - pointsDurationWidth
        Rectangle()
          .fill(colorScheme == .dark
            ? Color(uiColor: .systemBackground).opacity(0.6)
            : Color(uiColor: .secondarySystemBackground).opacity(0.8))
          .frame(width: max(0, -overflow))
      }
      .overlay {
        if isSelected {
          ClipTrimmingView(
            clip: clip,
            horizontalClipSpacing: clipSpacing,
            cornerRadius: cornerRadius,
            trimHandleWidth: configuration.trimHandleWidth,
            icon: clip.configuration.icon
          )
        }
      }
      .padding(.leading, pointsTimeOffsetWidth)
      .zIndex(isSelected ? 2 : 1)
      // Use .task instead of .onAppear to prevent animation glitches
      // when the timeline reappears when dismissing a sheet.
      .task {
        updateWidths(duration: clip.duration)
        updateTimeOffsetWidth(timeOffset: clip.timeOffset)
      }
      .onChange(of: clip.timeOffset) { newOffset in
        updateTimeOffsetWidth(timeOffset: newOffset)
      }
      .onChange(of: clip.trimOffset) { _ in
        updateWidths(duration: clip.duration)
      }
      .onChange(of: clip.duration) { newDuration in
        updateWidths(duration: newDuration)
      }
      .onChange(of: timeline.zoomLevel) { _ in
        updateWidths(duration: clip.duration)
        updateTimeOffsetWidth(timeOffset: clip.timeOffset)
      }
  }

  private func updateWidths(duration: CMTime?) {
    pointsTrimOffsetWidth = -timeline.convertToPoints(time: clip.trimOffset)
    guard let duration else {
      // If there is no duration set, we fill up the page’s totalDuration.
      let resolvedDurationSeconds = timeline.totalDuration - clip.timeOffset
      pointsDurationWidth = timeline.convertToPoints(time: resolvedDurationSeconds)
      return
    }
    pointsDurationWidth = timeline.convertToPoints(time: duration)
  }

  private func updateTimeOffsetWidth(timeOffset: CMTime) {
    pointsTimeOffsetWidth = timeline.convertToPoints(time: timeOffset)
  }
}

private struct Shimmering: ViewModifier {
  let isShimmering: Bool

  func body(content: Content) -> some View {
    if isShimmering {
      content
        .imgly.shimmer()
    } else {
      content
    }
  }
}
