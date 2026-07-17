import CoreMedia
@_spi(Internal) import IMGLYCore
import IMGLYEngine
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

  enum DraggingType {
    /// No dragging.
    case none

    /// Dragging the left handle.
    case trimStart

    /// Dragging the right handle.
    case trimEnd
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

  // MARK: - Live trim preview

  // See `ClipView+MoveDrag.swift` for the shared `previewTimeOffset` / commit model.
  // Trim drags never cross tracks, so cascade math is scoped to the source track.

  @State private var previewSiblingOriginals: [DesignBlockID: CMTime] = [:]

  var duration: CMTime {
    clip.duration ?? timeline.totalDuration - clip.timeOffset
  }

  /// Adjacent neighbours in the same track for collision detection in multi-clip tracks.
  var neighborBounds: (previousEnd: CMTime?, nextStart: CMTime?) {
    let dataSource = interactor.timelineProperties.dataSource
    guard let track = dataSource.findTrack(containing: clip),
          track.engineTrackID != nil else {
      return (nil, nil)
    }
    let (previous, next) = dataSource.neighborClips(of: clip, in: track)
    let previousEnd = previous.flatMap { prev in
      prev.duration.map { prev.displayTimeOffset + $0 }
    }
    let nextStart = next.map(\.displayTimeOffset)
    return (previousEnd, nextStart)
  }

  /// Cap for trim-end so the dragged clip can't overlap the nearest locked successor.
  /// Intermediate unlocked clips will be pushed, so their durations come out of the room.
  var maxEndForLockedClipCap: CMTime? {
    let dataSource = interactor.timelineProperties.dataSource
    guard let track = dataSource.findTrack(containing: clip),
          track.engineTrackID != nil else {
      return nil
    }
    let sorted = track.clips.sorted { $0.displayTimeOffset < $1.displayTimeOffset }
    guard let index = sorted.firstIndex(where: { $0.id == clip.id }) else {
      return nil
    }
    let after = sorted[(index + 1)...]
    guard let lockedIndex = after.firstIndex(where: { $0.isLocked }) else {
      return nil
    }
    let intermediateDuration = after[..<lockedIndex]
      .compactMap(\.duration)
      .reduce(CMTime.zero) { $0 + $1 }
    return after[lockedIndex].displayTimeOffset - intermediateDuration
  }

  /// Floor for trim-start: end of the nearest locked predecessor plus the durations
  /// of any unlocked clips between (which pack-push out of the way).
  var minStartFromPreviousPushRoom: CMTime? {
    let dataSource = interactor.timelineProperties.dataSource
    guard !clip.isInBackgroundTrack,
          let track = dataSource.findTrack(containing: clip),
          track.engineTrackID != nil else {
      return nil
    }
    let sorted = track.clips.sorted { $0.displayTimeOffset < $1.displayTimeOffset }
    guard let index = sorted.firstIndex(where: { $0.id == clip.id }),
          index > 0 else {
      return nil
    }

    var floor: CMTime = .zero
    var accumulated: CMTime = .zero
    for i in stride(from: index - 1, through: 0, by: -1) {
      let sibling = sorted[i]
      let duration = sibling.duration ?? .zero
      if sibling.isLocked {
        // Locked sibling — its end is the hard left boundary.
        floor = sibling.displayTimeOffset + duration
        break
      }
      // swiftlint:disable:next shorthand_operator
      accumulated = accumulated + duration
    }
    return floor + accumulated
  }

  private func snapshotSiblingsForPreview() {
    guard let track = interactor.timelineProperties.dataSource.findTrack(containing: clip),
          track.engineTrackID != nil else {
      previewSiblingOriginals = [:]
      return
    }
    let snapshot = Dictionary(uniqueKeysWithValues:
      track.clips.lazy.filter { $0.id != clip.id }.map { ($0.id, $0.timeOffset) })
    previewSiblingOriginals = snapshot
  }

  private func clearPreviewShadowAndSnapshots() {
    guard let track = interactor.timelineProperties.dataSource.findTrack(containing: clip) else {
      previewSiblingOriginals = [:]
      return
    }
    for sibling in track.clips where sibling.previewTimeOffset != nil {
      sibling.clearPreviewTimeOffset()
    }
    previewSiblingOriginals = [:]
  }

  /// Foreground tracks preserve authored gaps; background packs sequentially. Locked
  /// siblings always stay at their authored offset.
  private func previewPackRightSiblings(currentEnd: CMTime) {
    guard !previewSiblingOriginals.isEmpty,
          let track = interactor.timelineProperties.dataSource.findTrack(containing: clip) else { return }

    let preserveGaps = !clip.isInBackgroundTrack

    let rightSiblings = track.clips.compactMap { sibling -> (Clip, CMTime)? in
      guard sibling.id != clip.id,
            let original = previewSiblingOriginals[sibling.id],
            original >= clip.timeOffset else { return nil }
      return (sibling, original)
    }.sorted { $0.1 < $1.1 }

    var cursor = currentEnd
    for (sibling, original) in rightSiblings {
      if sibling.isLocked || (preserveGaps && original >= cursor) {
        applyPreviewIfChanged(on: sibling, target: original)
        cursor = original + (sibling.duration ?? .zero)
      } else {
        applyPreviewIfChanged(on: sibling, target: cursor)
        // swiftlint:disable:next shorthand_operator
        cursor = cursor + (sibling.duration ?? .zero)
      }
    }
  }

  /// Cascades unlocked predecessors leftward so they pack behind the trimmed clip's
  /// new leading edge. Locked predecessors stay put and cap further propagation.
  private func previewPushPreviousSibling(currentStart: CMTime) {
    guard !previewSiblingOriginals.isEmpty,
          let track = interactor.timelineProperties.dataSource.findTrack(containing: clip) else { return }

    // Right-to-left so the cascade ripples correctly.
    let predecessors = track.clips
      .compactMap { sibling -> (clip: Clip, original: CMTime)? in
        guard sibling.id != clip.id,
              let original = previewSiblingOriginals[sibling.id],
              original < clip.timeOffset else { return nil }
        return (sibling, original)
      }
      .sorted { $0.original > $1.original }

    // Boundary the next predecessor to the left must not overshoot. `nil` once a
    // locked sibling interrupts the cascade — anything further left restores.
    var rightEdge: CMTime? = currentStart
    for entry in predecessors {
      let sibling = entry.clip
      let original = entry.original
      guard let duration = sibling.duration else { continue }

      if sibling.isLocked {
        applyPreviewIfChanged(on: sibling, target: original)
        rightEdge = nil
        continue
      }

      guard let edge = rightEdge else {
        applyPreviewIfChanged(on: sibling, target: original)
        continue
      }

      if original + duration > edge {
        let newStart = edge - duration
        applyPreviewIfChanged(on: sibling, target: newStart)
        rightEdge = newStart
      } else {
        applyPreviewIfChanged(on: sibling, target: original)
        rightEdge = original
      }
    }
  }

  private func applyPreviewIfChanged(on sibling: Clip, target: CMTime) {
    if sibling.displayTimeOffset != target {
      sibling.applyPreview(timeOffset: target)
    }
  }

  var body: some View {
    ClipSelectionShape(cornerRadius: cornerRadius, trimHandleWidth: trimHandleWidth)
      .fill(isDragging || timeline.snapIndicatorLinePositions.contains(player.playheadPosition)
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
                - timeOffset - duration
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
        if isDragging,
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
          hasAnimation: clip.hasAnimation,
          basePadding: timeline.convertToPoints(time: startTrimOvershoot),
        )
      }
      .onPreferenceChange(ClipLabelWidthKey.self) { width in
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
      // Trim change while dragging
      .padding(.leading, timeline.convertToPoints(time: startTrimDurationDelta - startTrimOvershoot))
      .padding(.trailing, -timeline.convertToPoints(time: endTrimDurationDelta + endTrimOvershoot))
      // Visual content opts out of hit testing so touches on the clip body fall
      // through to `ClipView`'s long-press move recognizer.
      .allowsHitTesting(false)
      .overlay {
        HStack(spacing: 0) {
          ClipTrimmingGestureView(delegate: trimStartPanDelegate)
            .frame(width: trimHandleWidth * 2)
          // Middle stays transparent so the long-press recognizer below receives touches.
          Spacer()
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
    interactor.startScrubbing(clip: clip)
    self.draggingType = draggingType

    previousTranslationWidth = 0

    // Trim-start and trim-end preview-push siblings. Snapshot their authored offsets
    // so we can restore them on cancel.
    if draggingType == .trimStart || draggingType == .trimEnd {
      snapshotSiblingsForPreview()
    }
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
      var maxNegativeDelta: CMTime
      let maxPositiveDelta: CMTime

      if clip.effectiveFootageDuration != nil {
        maxNegativeDelta = clip.isLooping ? .negativeInfinity : clip.trimOffset.imgly.makeNegative()
      } else {
        maxNegativeDelta = clip.isInBackgroundTrack ? .negativeInfinity : clip.timeOffset.imgly.makeNegative()
      }

      // In multi-clip tracks, the left edge can be pushed past the previous clip's end
      // if that clip is unlocked and has room to shift left. The clamp matches the
      // minimum achievable start once the predecessor is pushed as far as it can go.
      if let minStart = minStartFromPreviousPushRoom {
        let neighborLimit = minStart - clipStartTime
        maxNegativeDelta = max(maxNegativeDelta, neighborLimit)
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

        // Always track the latest resolved delta so the drag follows the
        // snap target as it changes between zones; only the haptic + indicator
        // flip on first entry into a snap zone.
        startTrimDurationDelta = resolvedDelta
        if !hasSnapped {
          hasSnapped = true
          timeline.snapIndicatorLinePositions.append(clipStartTime + snappedDelta)
        }
      } else {
        hasSnapped = false

        startTrimDurationDelta = resolvedDelta
        timeline.snapIndicatorLinePositions.removeAll()
      }

      // Preview: foreground tracks push the previous sibling leftward; background track
      // grows the duration and shifts all right siblings (no leftward push possible).
      if clip.isInBackgroundTrack {
        let newEnd = clipStartTime + duration - startTrimDurationDelta
        previewPackRightSiblings(currentEnd: newEnd)
        // Publish the live delta so UI anchored to the background end (e.g. the
        // "+ Add Clip" button) follows the preview. `endTrimDurationDelta - startTrimDurationDelta`
        // gives the total shift of the track's end.
        interactor.timelineProperties.backgroundTrackTrimDelta =
          endTrimDurationDelta - startTrimDurationDelta
      } else {
        previewPushPreviousSibling(currentStart: clipStartTime + startTrimDurationDelta)
      }

    case .trimEnd:
      let maxNegativeDelta: CMTime
      var maxPositiveDelta: CMTime

      if let footageDuration = clip.effectiveFootageDuration, !clip.isLooping {
        maxNegativeDelta = (duration - configuration.minClipDuration).imgly.makeNegative()
        maxPositiveDelta = footageDuration - clip.trimOffset - duration
      } else {
        maxNegativeDelta = duration.imgly.makeNegative() + configuration.minClipDuration
        maxPositiveDelta = .positiveInfinity
      }

      // No constraint from unlocked neighbors — growing pushes them (handled by
      // packAndPersistTrackClips in setTrim). But we cap at the nearest LOCKED clip's
      // start (accounting for intermediate unlocked clips that pack will push too).
      if let maxEnd = maxEndForLockedClipCap {
        let lockedLimit = maxEnd - clipStartTime - duration
        maxPositiveDelta = min(maxPositiveDelta, lockedLimit)
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

        // Always track the latest resolved delta so the drag follows the
        // snap target as it changes between zones; only the haptic + indicator
        // flip on first entry into a snap zone.
        endTrimDurationDelta = resolvedDelta
        if !hasSnapped {
          hasSnapped = true
          timeline.snapIndicatorLinePositions.append(clipStartTime + duration + resolvedDelta)
        }
      } else {
        hasSnapped = false

        endTrimDurationDelta = resolvedDelta
        timeline.snapIndicatorLinePositions.removeAll()
      }

      // Preview-push right-side siblings live to match what pack will produce on submit.
      previewPackRightSiblings(currentEnd: clipStartTime + duration + endTrimDurationDelta)
      if clip.isInBackgroundTrack {
        interactor.timelineProperties.backgroundTrackTrimDelta =
          endTrimDurationDelta - startTrimDurationDelta
      }

      // Show solo playback for this clip:
      let scrubPosition = clip.trimOffset + duration + endTrimDurationDelta
      interactor.scrub(clip: clip, time: scrubPosition)
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

    if cancelled {
      // `timeOffset` was never touched during drag — clearing the preview shadow
      // is all it takes to snap siblings back to their pre-drag positions.
      clearPreviewShadowAndSnapshots()
      startTrimDurationDelta = .zero
      endTrimDurationDelta = .zero
      // Background trim delta is published live during drag for the "+ Add Clip"
      // anchor. Reset it on cancel so the anchor snaps back to the authored end.
      if clip.isInBackgroundTrack, interactor.timelineProperties.backgroundTrackTrimDelta != .zero {
        interactor.timelineProperties.backgroundTrackTrimDelta = .zero
      }
      return
    }

    // If clip was trimmed:
    let timeOffset = max(.zero, clip.timeOffset + startTrimDurationDelta)

    let trimOffset = clip.trimOffset + startTrimDurationDelta
    let duration = duration + endTrimDurationDelta - startTrimDurationDelta

    // Commit any preview-pushed siblings to the engine first — otherwise
    // `Track::layout()` would see stale positions when `setTrim` runs and push the
    // dragged clip away from the just-trimmed edge. Build an explicit
    // `[blockID: newOffset]` map from each sibling whose preview moved it off its
    // authored position.
    var commitOffsets: [DesignBlockID: CMTime] = [:]
    if let track = interactor.timelineProperties.dataSource.findTrack(containing: clip) {
      for (siblingID, original) in previewSiblingOriginals {
        guard let sibling = track.clips.first(where: { $0.id == siblingID }),
              let preview = sibling.previewTimeOffset,
              preview != original else { continue }
        commitOffsets[siblingID] = preview
      }
    }
    if !commitOffsets.isEmpty {
      interactor.commitPreviewedOffsets(commitOffsets)
    }
    clearPreviewShadowAndSnapshots()

    // Reset the live BG trim delta before `setTrim` so the "+ Add Clip" anchor (which
    // reads `totalDuration + backgroundTrackTrimDelta`) doesn't render the old delta
    // alongside the just-published new totalDuration. `setTrim`'s `updateDurations`
    // computes the new total from local BG clip durations, so no pre-write needed.
    if clip.isInBackgroundTrack, interactor.timelineProperties.backgroundTrackTrimDelta != .zero {
      interactor.timelineProperties.backgroundTrackTrimDelta = .zero
    }

    interactor.setTrim(clip: clip, timeOffset: timeOffset, trimOffset: trimOffset, duration: duration)

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
    return (1.0 - (1.0 / divisor)) * 10
  }
}
