import CoreMedia
@_spi(Internal) import IMGLYCore
import SwiftUI
import UIKit

/// The `ClipTrimmingView` manages the interaction and behavior for trimming and moving clips in the timeline.
struct ClipTrimmingView: View {
  @EnvironmentObject var interactor: AnyTimelineInteractor
  @EnvironmentObject var player: Player
  @EnvironmentObject var timeline: Timeline
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.imglyViewportWidth) private var viewportWidth
  @Environment(\.imglyTimelineConfiguration) var configuration: TimelineConfiguration

  @StateObject var trimStartPanDelegate = ClipTrimmingPanGestureRecognizerDelegate()
  @StateObject var trimEndPanDelegate = ClipTrimmingPanGestureRecognizerDelegate()
  @StateObject var movePanDelegate = ClipTrimmingPanGestureRecognizerDelegate()

  enum DraggingType {
    /// No dragging.
    case none

    /// Dragging the left handle.
    case trimStart

    /// Dragging the right handle.
    case trimEnd

    /// Moving the clip.
    case move
  }

  enum SwipeDirection {
    case left
    case right
  }

  @ObservedObject var clip: Clip

  let horizontalClipSpacing: CGFloat
  let cornerRadius: CGFloat
  let trimHandleWidth: CGFloat

  let icon: Image?

  /// Tracks whether a trim or move drag is in progess. Pauses playback while dragging.
  @State private var isDragging: Bool = false {
    didSet {
      if isDragging {
        interactor.pause()
      }
    }
  }

  @State private var startTrimDurationDelta: CMTime = .zero
  @State private var endTrimDurationDelta: CMTime = .zero

  @State private var startTrimOvershoot: CMTime = .zero
  @State private var endTrimOvershoot: CMTime = .zero

  @State private var offsetDelta: CMTime = .zero
  @State private var draggingType: DraggingType = .none

  @State private var previousTranslationWidth: CGFloat = 0
  @State private var swipeDirection: SwipeDirection = .left

  @State private var relativeSnapDetents = [SnapDetent]()
  @State private var hasSnapped = false {
    didSet {
      guard hasSnapped, hasSnapped != oldValue else { return }
      HapticsHelper.shared.timelineSnap()
    }
  }

  @State private var labelWidth: CGFloat = 0

  var duration: CMTime {
    let duration = clip.duration ?? timeline.totalDuration - clip.timeOffset
    return duration
  }

  var body: some View {
    ClipSelectionShape(cornerRadius: cornerRadius, trimHandleWidth: trimHandleWidth)
      .fill(isDragging
        && ((!clip.isInBackgroundTrack && draggingType == .move)
          || draggingType != .move) || timeline.snapIndicatorLinePositions.contains(player.playheadPosition)
        ? configuration.clipSelectionActiveColor
        : configuration.clipSelectionColor)
      .padding(.horizontal, -trimHandleWidth)
      .padding(.vertical, -2)
      .background(alignment: .leading) {
        if let thumbnailsProvider = try? interactor.timelineProperties.thumbnailsManager.getProvider(clip: clip) {
          ClipBackgroundView(
            clip: clip,
            cornerRadius: cornerRadius,
            pointsTrimOffsetWidth: -timeline.convertToPoints(time: startTrimDurationDelta),
            thumbnailsProvider: AnyThumbnailsProvider(erasing: thumbnailsProvider),
            labelWidth: labelWidth,
          )
          .padding(.leading, timeline.convertToPoints(time: startTrimOvershoot))
          // Dimming overlay where clip exceeds total duration
          .overlay(alignment: .trailing) {
            let overlayDuration = player.maxPlaybackDuration ?? timeline.totalDuration
            let timeOffset = clip.isInBackgroundTrack ? .zero : clip.timeOffset
            let overflow = timeline.convertToPoints(
              time: overlayDuration
                - timeOffset - duration - offsetDelta
                - endTrimDurationDelta - endTrimOvershoot,
            )
            Rectangle()
              .fill(colorScheme == .dark
                ? Color(uiColor: .systemBackground).opacity(0.5)
                : Color(uiColor: .secondarySystemBackground).opacity(0.7))
              .opacity(0.8)
              .frame(width: max(0, -overflow))
          }
        }
      }

      // Marching Ants placeholder
      .background {
        if isDragging, draggingType != .move,
           let footageDuration = clip.effectiveFootageDuration,
           !clip.isLooping {
          ZStack {
            ClipSelectionShape(cornerRadius: cornerRadius, trimHandleWidth: trimHandleWidth)
              .fill(configuration.clipSelectionActiveColor.opacity(0.2))
              .padding(.horizontal, -trimHandleWidth)
              .padding(.vertical, -2)

            MarchingAntsRectangleView(cornerRadius: cornerRadius)
              .foregroundColor(configuration.clipSelectionActiveColor)
          }
          .frame(width: timeline.convertToPoints(time: footageDuration))
          // Including the clip spacing would make trimming feel less accurate (1/2)
          // .padding(.trailing, clipSpacing)
          .padding(.leading, -timeline.convertToPoints(time: clip.trimOffset
              + startTrimDurationDelta
              - startTrimOvershoot))
          .padding(.trailing, -timeline.convertToPoints(time: footageDuration - duration - clip.trimOffset
              - endTrimDurationDelta
              - endTrimOvershoot))
        }
      }
      // Label with pinning behavior
      .overlay {
        ClipLabelView(
          duration: clip.isLoading ? nil : duration - startTrimDurationDelta + endTrimDurationDelta,
          icon: icon,
          title: clip.title,
          isMuted: clip.audioVolume == 0 || clip.isMuted,
          isSelectable: clip.allowsSelecting,
          cornerRadius: cornerRadius - 2,
          isLooping: clip.isLooping,
          basePadding: timeline.convertToPoints(time: startTrimOvershoot),
        )
      }
      .onPreferenceChange(ClipLabelWidthKey.self) { width in
        // Only update if changed to avoid unnecessary re-renders
        if labelWidth != width {
          labelWidth = width
        }
      }
      // Left and right handle icons
      .overlay(alignment: .leading) {
        let hasLeadingOvershoot = !clip
          .isLooping && ((clip.trimOffset + startTrimDurationDelta).seconds > 0 || !clip.allowsTrimming)
        ClipTrimHandleIconView(style: hasLeadingOvershoot ? .left : .neutral,
                               color: .white)
          .offset(x: -11)
      }
      .overlay(alignment: .trailing) {
        let footageDuration = clip.effectiveFootageDuration ?? CMTime(seconds: 0)
        let hasTrailingOvershoot = clip
          .isLooping || (footageDuration - clip.trimOffset - duration - endTrimDurationDelta).seconds > 0
        ClipTrimHandleIconView(style: hasTrailingOvershoot || !clip.allowsTrimming ? .right : .neutral,
                               color: .white)
          .offset(x: 11)
      }
      // Including the clip spacing would make trimming feel less accurate (2/2)
      // .padding(.trailing, clipSpacing)
      // Offset and trim change while dragging
      .padding(.leading, timeline.convertToPoints(time: startTrimDurationDelta - startTrimOvershoot))
      .padding(.trailing, -timeline.convertToPoints(time: endTrimDurationDelta + endTrimOvershoot))
      .offset(x: timeline.convertToPoints(time: offsetDelta))
      .overlay {
        HStack(spacing: 0) {
          // Left trim handle gesture
          ClipTrimmingGestureView(delegate: trimStartPanDelegate)
            .frame(width: trimHandleWidth * 2)

          // Move clip gesture
          if !clip.isInBackgroundTrack {
            ClipTrimmingGestureView(delegate: movePanDelegate)
          } else {
            Spacer()
          }

          // Right trim handle gesture
          ClipTrimmingGestureView(delegate: trimEndPanDelegate)
            .frame(width: trimHandleWidth * 2)
        }
        // The handles stick out and are twice as wide as they appear to make them easier to grab.
        .padding(.horizontal, -trimHandleWidth * 2)
      }

      .onChange(of: trimStartPanDelegate.state) { state in
        switch state {
        case .began:
          startDrag(draggingType: .trimStart)
        case .ended:
          endDrag()
        case .cancelled:
          endDrag(cancelled: true)
        default:
          break
        }
      }
      .onChange(of: trimStartPanDelegate.translation) { translation in
        if isDragging {
          updateDrag(translationWidth: translation.x)
        }
      }

      .onChange(of: movePanDelegate.state) { state in
        switch state {
        case .began:
          startDrag(draggingType: .move)
        case .ended:
          endDrag()
        case .cancelled:
          endDrag(cancelled: true)
        default:
          break
        }
      }
      .onChange(of: movePanDelegate.translation) { translation in
        if isDragging {
          updateDrag(translationWidth: translation.x)
        }
      }

      .onChange(of: trimEndPanDelegate.state) { state in
        switch state {
        case .began:
          startDrag(draggingType: .trimEnd)
        case .ended:
          endDrag()
        case .cancelled:
          endDrag(cancelled: true)
        default:
          break
        }
      }
      .onChange(of: trimEndPanDelegate.translation) { translation in
        if isDragging {
          updateDrag(translationWidth: translation.x)
        }
      }
  }

  private func startDrag(draggingType: DraggingType) {
    updateSnapDetents()

    isDragging = true
    if draggingType != .move {
      interactor.startScrubbing(clip: clip)
    }
    self.draggingType = draggingType

    previousTranslationWidth = 0
  }

  // swiftlint:disable:next cyclomatic_complexity
  private func updateDrag(translationWidth: CGFloat) {
    guard !timeline.isPinchingZoom else { return }
    guard !timeline.isDraggingTimeline else { return }
    guard !clip.isLoading else { return }

    swipeDirection = translationWidth > previousTranslationWidth ? .right : .left
    previousTranslationWidth = translationWidth

    let proposedDraggingDelta = translationWidth
    let proposedDurationDelta = timeline.convertToTime(points: proposedDraggingDelta)

    let clipStartTime = clip.timeOffset

    switch draggingType {
    case .none:
      break

    case .trimStart:
      let maxNegativeDelta: CMTime
      let maxPositiveDelta: CMTime

      if clip.effectiveFootageDuration != nil {
        maxNegativeDelta = clip.isLooping ? .negativeInfinity : clip.trimOffset.imgly.makeNegative()
      } else {
        maxNegativeDelta = clip.isInBackgroundTrack ? .negativeInfinity : clip.timeOffset.imgly.makeNegative()
      }
      maxPositiveDelta = duration - configuration.minClipDuration

      var constrainedDelta: CMTime

      if proposedDurationDelta < .zero {
        constrainedDelta = max(maxNegativeDelta, proposedDurationDelta)
        startTrimOvershoot = CMTime(seconds:
          rubberband(constrainedDelta.seconds - proposedDurationDelta.seconds))
      } else {
        constrainedDelta = min(maxPositiveDelta, proposedDurationDelta)
      }

      // Show solo playback for this clip:
      let scrubPosition = clip.trimOffset + constrainedDelta
      interactor.scrub(clip: clip, time: scrubPosition)

      // Only snap the left handle for clips that can have a time offset
      guard !clip.isInBackgroundTrack else {
        startTrimDurationDelta = constrainedDelta
        break
      }

      var resolvedDelta = constrainedDelta
      let snappedDelta = snap(constrainedDelta)

      if let snappedDelta {
        if proposedDurationDelta < .zero {
          resolvedDelta = max(maxNegativeDelta, snappedDelta)
        } else {
          resolvedDelta = min(maxPositiveDelta, snappedDelta)
        }

        if !hasSnapped {
          hasSnapped = true
          timeline.snapIndicatorLinePositions.append(clipStartTime + snappedDelta)
          startTrimDurationDelta = resolvedDelta
        }
      } else {
        hasSnapped = false

        startTrimDurationDelta = resolvedDelta
        timeline.snapIndicatorLinePositions.removeAll()
      }

    case .trimEnd:
      let maxNegativeDelta: CMTime
      let maxPositiveDelta: CMTime

      if let footageDuration = clip.effectiveFootageDuration, !clip.isLooping {
        maxNegativeDelta = (duration - configuration.minClipDuration).imgly.makeNegative()
        maxPositiveDelta = footageDuration - clip.trimOffset - duration
      } else {
        maxNegativeDelta = duration.imgly.makeNegative() + configuration.minClipDuration
        maxPositiveDelta = .positiveInfinity
      }

      var constrainedDelta: CMTime

      if proposedDurationDelta < .zero {
        constrainedDelta = max(maxNegativeDelta, proposedDurationDelta)
      } else {
        constrainedDelta = min(maxPositiveDelta, proposedDurationDelta)

        endTrimOvershoot =
          CMTime(seconds: rubberband(proposedDurationDelta.seconds - constrainedDelta.seconds))
      }

      var resolvedDelta = constrainedDelta

      let snappedDelta = snap(constrainedDelta + duration)

      if let snappedDelta {
        if proposedDurationDelta < .zero {
          resolvedDelta = max(maxNegativeDelta, snappedDelta - duration)
        } else {
          resolvedDelta = min(maxPositiveDelta, snappedDelta - duration)
        }

        if !hasSnapped {
          hasSnapped = true

          timeline.snapIndicatorLinePositions.append(clipStartTime + duration + resolvedDelta)
          endTrimDurationDelta = resolvedDelta
        }
      } else {
        hasSnapped = false

        endTrimDurationDelta = resolvedDelta
        timeline.snapIndicatorLinePositions.removeAll()
      }

      // Show solo playback for this clip:
      let scrubPosition = clip.trimOffset + duration + endTrimDurationDelta
      interactor.scrub(clip: clip, time: scrubPosition)

    case .move:
      guard !clip.isInBackgroundTrack else { break }

      let minNegativeOffsetDelta = clip.timeOffset.imgly.makeNegative()
      var offsetDelta = max(minNegativeOffsetDelta, proposedDurationDelta)

      // This detail is important if the move operation would snap to the start and end at once. If that is the case, we
      // consider the direction, and prefer the right edge only if movement is rightwards.
      if let snap = snap(offsetDelta + duration),
         self.snap(offsetDelta) == nil || swipeDirection == .right {
        // Snap to the end
        if !hasSnapped {
          hasSnapped = true

          offsetDelta = snap - duration
          timeline.snapIndicatorLinePositions.append(clipStartTime + duration + offsetDelta)
          self.offsetDelta = offsetDelta

          // Check if we also display a snap indicator line at the start
          if interactor.timelineProperties.dataSource.snapDetents.contains(clipStartTime + offsetDelta) {
            timeline.snapIndicatorLinePositions.append(clipStartTime + offsetDelta)
          }
        }
      } else if let snap = snap(offsetDelta) {
        // Snap to the start
        if !hasSnapped {
          hasSnapped = true

          offsetDelta = snap
          timeline.snapIndicatorLinePositions.append(clipStartTime + offsetDelta)
          self.offsetDelta = offsetDelta

          // Check if we also display a snap indicator line at the end
          if interactor.timelineProperties.dataSource.snapDetents.contains(clipStartTime + duration + offsetDelta) {
            timeline.snapIndicatorLinePositions.append(clipStartTime + duration + offsetDelta)
          }
        }
      } else {
        // Unsnap
        hasSnapped = false

        timeline.snapIndicatorLinePositions.removeAll()
        self.offsetDelta = offsetDelta
      }
    }
  }

  private func endDrag(cancelled: Bool = false) {
    interactor.stopScrubbing(clip: clip)
    defer {
      isDragging = false
      draggingType = .none
      hasSnapped = false
      timeline.snapIndicatorLinePositions.removeAll()
    }

    guard !cancelled else { return }

    // If clip was trimmed:
    var timeOffset = max(.zero, clip.timeOffset + startTrimDurationDelta)
    // If clip was moved:
    // swiftlint:disable:next shorthand_operator
    timeOffset = timeOffset + offsetDelta

    let trimOffset = clip.trimOffset + startTrimDurationDelta
    let duration = duration + endTrimDurationDelta - startTrimDurationDelta

    interactor.setTrim(clip: clip, timeOffset: timeOffset, trimOffset: trimOffset, duration: duration)

    offsetDelta = .zero
    startTrimDurationDelta = .zero
    endTrimDurationDelta = .zero

    if startTrimOvershoot != .zero || endTrimOvershoot != .zero {
      HapticsHelper.shared.timelineTrimmingRubberband()
    }

    withAnimation(.interpolatingSpring(mass: 0.01,
                                       stiffness: 8.0,
                                       damping: 0.21,
                                       initialVelocity: 10.0)) {
      startTrimOvershoot = .zero
      endTrimOvershoot = .zero
    }
  }

  // MARK: - Snapping Helpers

  private func updateSnapDetents() {
    var snapDetents = interactor.timelineProperties.dataSource.snapDetents

    if clip.isInBackgroundTrack {
      // Background track only snaps to the playhead
      snapDetents.removeAll()
    }

    // Inset the visible range so that snapping doesn’t happen right on the screen edge.
    let padding: CGFloat = 4
    let distanceInTime = timeline.convertToTime(points: viewportWidth / 2 - padding)
    let leftEdgeTime = player.playheadPosition - distanceInTime
    let rightEdgeTime = player.playheadPosition + distanceInTime
    let visibleRange = leftEdgeTime ... rightEdgeTime

    // Drop all the snap detents that are not currently visible in the viewport.
    snapDetents.removeAll(where: { !visibleRange.contains($0) })

    // We add the playhead position last because the snap detens are processed sequentially and
    // the background track clip times are more important as snap points than the playhead.
    // They should especially have precedence as long as the playhead shifting while
    // zooming due to rounding errors is resolved.
    snapDetents.append(player.playheadPosition)

    let snapTolerance = timeline.convertToTime(points: 5)

    let absoluteStartPosition = clip.timeOffset

    relativeSnapDetents = snapDetents.map { detent in
      let snap = detent - absoluteStartPosition
      let range = (snap - snapTolerance) ... (snap + snapTolerance)
      return SnapDetent(range: range, snap: snap)
    }
  }

  private func snap(_ relativeTime: CMTime) -> CMTime? {
    relativeSnapDetents.first(where: { $0.range.contains(relativeTime) })?.snap
  }

  // MARK: - Rubberbanding

  private func rubberband(_ seconds: CGFloat) -> CGFloat {
    let divisor = (seconds * 0.05) + 1.0
    let result = (1.0 - (1.0 / divisor)) * 10
    return result
  }
}
