import CoreMedia
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEngine
import SwiftUI

/// A `ClipView` that is displayed in the `TimelineView`.
struct ClipView: View {
  private enum Metrics {
    static let borderWidthClip: CGFloat = 2.0
  }

  @EnvironmentObject var timeline: Timeline
  @EnvironmentObject var timelineProperties: TimelineProperties
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.imglyTimelineConfiguration) var configuration: TimelineConfiguration

  @ObservedObject private(set) var clip: Clip
  private let isSelected: Bool

  @State private var pointsDurationWidth: CGFloat = 0
  @State private var pointsTrimOffsetWidth: CGFloat = 0
  @State private var labelWidth: CGFloat = 0

  // Computed live (not cached in `@State`) because `refreshTimeline()` replaces Clip
  // instances behind a reused ClipView; cached state would render a stale offset.
  private var pointsTimeOffsetWidth: CGFloat {
    timeline.convertToPoints(time: clip.displayTimeOffset)
  }

  // Move-drag state lives here, not in `ClipTrimmingView`, so the long-press works on
  // unselected clips too (`ClipTrimmingView` only mounts for the selected clip).
  @StateObject var movePanDelegate = ClipMoveLongPressGestureRecognizerDelegate()
  @State var isMoveDragging: Bool = false
  @State var offsetDelta: CMTime = .zero
  @State var previewSiblingOriginals: [DesignBlockID: CMTime] = [:]
  @State var previewTrackSnapshots: [UUID: [DesignBlockID: CMTime]] = [:]

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
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius - 2).inset(by: clip.clipType != .voiceOver ? 0 : 1))
      .background {
        if let thumbnailsProvider = try? timelineProperties.thumbnailsManager.getProvider(clip: clip) {
          ClipBackgroundView(
            clip: clip,
            cornerRadius: cornerRadius,
            pointsTrimOffsetWidth: 0,
            thumbnailsProvider: AnyThumbnailsProvider(erasing: thumbnailsProvider),
            labelWidth: labelWidth,
          )
          .overlay {
            RoundedRectangle(cornerRadius: cornerRadius - 1)
              .inset(by: 0.25)
              .strokeBorder(
                clip.configuration.color.opacity(0.25),
                style: clip.allowsSelecting
                  ? SwiftUI.StrokeStyle(lineWidth: 0.5)
                  : SwiftUI.StrokeStyle(lineWidth: 0.5, dash: [2], dashPhase: 4),
              )
          }
          .opacity(clipOpacity)
          .modifier(Shimmering(isShimmering: clip.isLoading))
        }
      }
      .opacity(clip.allowsSelecting ? 1 : 0.3)
      .overlay {
        if !isSelected {
          ClipLabelView(
            duration: nil,
            icon: clip.configuration.icon,
            title: unselectedClipLabelTitle,
            isMuted: clip.audioVolume == 0 || clip.isMuted,
            isSelectable: clip.allowsSelecting,
            cornerRadius: cornerRadius - 2,
            isLooping: clip.isLooping,
            hasAnimation: clip.hasAnimation,
          )
        }
      }
      .onPreferenceChange(ClipLabelWidthKey.self) { width in
        if labelWidth != width {
          labelWidth = width
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
        let maxDuration = timelineProperties.player.maxPlaybackDuration ?? timeline.totalDuration
        let maxWidth = timeline.convertToPoints(time: maxDuration)
        let overflow = maxWidth - pointsTimeOffsetWidth - pointsDurationWidth
        Rectangle()
          .fill(colorScheme == .dark
            ? Color(uiColor: .systemBackground).opacity(0.6)
            : Color(uiColor: .secondarySystemBackground).opacity(0.8))
          .frame(width: max(0, -overflow))
      }
      // Sits below the selection overlay so the trim handles still absorb their own
      // touches; `ClipTrimmingView`'s visual content is hit-test disabled so the clip
      // body falls through to this recognizer.
      .overlay {
        if clip.allowsSelecting {
          ClipMoveLongPressGestureView(delegate: movePanDelegate)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
      .overlay(selectedOverlay)
      // Hide the in-track render while dragging — `FloatingClipOverlayView` at the
      // timeline root takes over so the clip lifts above its track's bounds. Padding
      // stays applied so siblings don't reflow.
      .opacity(isBeingDragged ? 0 : 1)
      .padding(.leading, pointsTimeOffsetWidth)
      .zIndex(isSelected ? 2 : 1)
      // Use .task instead of .onAppear to prevent animation glitches
      // when the timeline reappears when dismissing a sheet.
      .task {
        updateWidths(duration: clip.duration)
      }
      .onChange(of: clip.trimOffset) { _ in
        updateWidths(duration: clip.duration)
      }
      .onChange(of: clip.duration) { newDuration in
        updateWidths(duration: newDuration)
      }
      .onChange(of: timeline.zoomLevel) { _ in
        updateWidths(duration: clip.duration)
      }

      // See `ClipView+MoveDrag.swift` for the flow. Translation is observed separately
      // because `onChange(of: phase)` doesn't re-fire on consecutive `.changed` events.
      .onChange(of: movePanDelegate.phase) { phase in
        onMovePhaseChanged(phase)
      }
      .onChange(of: movePanDelegate.translation) { _ in
        onMoveTranslationChanged()
      }
      // Re-run the preview when auto-scroll moves the timeline, so the drop slot keeps
      // tracking the finger without requiring the user to actually move it.
      .onChange(of: timelineProperties.horizontalScrollOffsetPoints) { _ in
        onMoveDragScrollOffsetChanged()
      }
  }

  private var clipOpacity: Double {
    if !isSelected { return 1 }
    if clip.clipType == .voiceOver, !clip.allowsTrimming { return 1 }
    return 0
  }

  private var isBeingDragged: Bool {
    if case let .dragging(context) = timelineProperties.dragDropState,
       context.clipID == clip.id {
      return true
    }
    return false
  }

  @ViewBuilder
  private var selectedOverlay: some View {
    if isSelected {
      switch clip.clipType {
      case .voiceOver where !clip.allowsTrimming:
        selectedView
      default:
        selectedTrimmingView
      }
    }
  }

  private var selectedTrimmingView: some View {
    ClipTrimmingView(
      clip: clip,
      horizontalClipSpacing: clipSpacing,
      cornerRadius: configuration.cornerRadius,
      trimHandleWidth: configuration.trimHandleWidth,
      icon: clip.configuration.icon,
    )
    .id(ObjectIdentifier(clip))
  }

  private var selectedView: some View {
    Rectangle()
      .fill(Color.clear)
      .clipShape(RoundedRectangle(cornerRadius: configuration.cornerRadius))
      .overlay(
        RoundedRectangle(cornerRadius: configuration.cornerRadius)
          .stroke(configuration.clipSelectionColor, lineWidth: Metrics.borderWidthClip),
      )
      .overlay {
        ClipLabelView(
          duration: nil,
          icon: clip.configuration.icon,
          title: selectedClipLabelTitle,
          isMuted: clip.audioVolume == 0 || clip.isMuted,
          isSelectable: clip.allowsSelecting,
          cornerRadius: configuration.cornerRadius,
          isLooping: clip.isLooping,
          hasAnimation: clip.hasAnimation,
        )
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

  private var unselectedClipLabelTitle: String {
    if clip.clipType == .voiceOver {
      ""
    } else {
      clip.title
    }
  }

  private var selectedClipLabelTitle: String {
    switch clip.clipType {
    case .text:
      ""
    case .voiceOver:
      isSelected ? (clip.title.isEmpty ? clip.clipType.description : clip.title) : ""
    default:
      clip.title.isEmpty ? clip.clipType.description : clip.title
    }
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
