import CoreMedia
@_spi(Internal) import IMGLYCore
import IMGLYEngine
import SwiftUI

// MARK: - Move drag & drop (long-press gated)

// Lives on `ClipView` (not the selection-only `ClipTrimmingView`) so the gesture
// works on unselected clips. Preview mutates `previewTimeOffset` only; the authored
// `timeOffset` is never touched until commit hands sibling offsets to the interactor.

extension ClipView {
  // MARK: - Lifecycle

  func onMovePhaseChanged(_ phase: ClipMoveLongPressGestureRecognizerDelegate.Phase) {
    switch phase {
    case .began:
      if timelineProperties.selectedClip?.id != clip.id {
        timeline.interactor?.select(id: clip.id)
      }
      HapticsHelper.shared.timelineReorderStart()
      startMoveDrag()
      startMoveDragDropPreview(location: movePanDelegate.windowLocation)
    case .ended:
      if isMoveDragging {
        endMoveDrag()
        endMoveDragDropPreview()
      }
      movePanDelegate.reset()
    case .cancelled:
      if isMoveDragging {
        endMoveDrag(cancelled: true)
        endMoveDragDropPreview()
      }
      movePanDelegate.reset()
    case .changed, .idle:
      break
    }
  }

  // `.onChange(of: phase)` doesn't fire on consecutive `.changed` events, so movement
  // after `.began` is driven from this separate observer.
  func onMoveTranslationChanged() {
    guard isMoveDragging else { return }
    updateMoveDragDropPreview(location: movePanDelegate.windowLocation)
    updateMoveDrag(translationWidth: movePanDelegate.translation.x)
  }

  func onMoveDragScrollOffsetChanged() {
    guard isMoveDragging else { return }
    updateMoveDrag(translationWidth: movePanDelegate.translation.x)
  }

  // MARK: - Drag state

  func startMoveDrag() {
    timeline.interactor?.pause()
    isMoveDragging = true
    snapshotSiblingsForMovePreview()
  }

  func updateMoveDrag(translationWidth: CGFloat) {
    guard !timeline.isPinchingZoom else { return }
    guard !timeline.isDraggingTimeline else { return }
    guard !clip.isLoading else { return }
    let proposedDurationDelta = timeline.convertToTime(points: translationWidth)
    updateMoveDragDropPreview(proposedDelta: proposedDurationDelta)
  }

  func endMoveDrag(cancelled: Bool = false) {
    defer {
      isMoveDragging = false
    }

    timeline.snapIndicatorLinePositions.removeAll()

    if cancelled {
      clearPreviewShadowAndSnapshots()
      offsetDelta = .zero
      return
    }

    if case let .dragging(context) = timelineProperties.dragDropState,
       let dropTarget = context.dropTarget {
      timeline.interactor?.applyDrop(
        clip: clip,
        target: dropTarget,
        siblingOffsets: collectPreviewOffsets(),
      )
      offsetDelta = .zero
      clearPreviewShadowAndSnapshots()
      // Flip the state inline so overlay hide / clip reveal / track rebuild land in
      // one SwiftUI pass. Letting the outer `.onChange` clear it leaves the overlay
      // visible for a frame while the rebuilt track structure renders.
      timelineProperties.dragDropState = .idle
      HapticsHelper.shared.timelineReorderFinish()
    } else {
      clearPreviewShadowAndSnapshots()
      offsetDelta = .zero
    }
  }

  // MARK: - DragDropState publishing (observed by FloatingClipOverlayView et al.)

  func startMoveDragDropPreview(location: CGPoint) {
    guard let track = timelineProperties.dataSource.findTrack(containing: clip) else { return }
    // Pin the finger to its initial spot on the clip. Centring the floating overlay
    // would hide one edge for clips wider than the viewport.
    let grabOffsetX = movePanDelegate.initialLocationInView.x
    let grabOffsetY = movePanDelegate.initialLocationInView.y

    let context = DragContext(
      clipID: clip.id,
      sourceTrackID: track.id,
      initialTimeOffset: clip.timeOffset,
      initialTouchLocation: location,
      currentTouchLocation: location,
      initialScrollOffset: timelineProperties.horizontalScrollOffsetPoints,
      grabOffsetX: grabOffsetX,
      grabOffsetY: grabOffsetY,
    )
    timelineProperties.dragDropState = .dragging(context)
  }

  func updateMoveDragDropPreview(location: CGPoint) {
    guard case var .dragging(context) = timelineProperties.dragDropState else { return }
    context.currentTouchLocation = location
    timelineProperties.dragDropState = .dragging(context)
  }

  func endMoveDragDropPreview() {
    timelineProperties.dragDropState = .idle
  }

  // MARK: - Snapshots

  /// Captures siblings' authored `timeOffset` at drag start. The preview shadow moves
  /// during drag, so cascade math reads "original position" from this snapshot instead.
  private func snapshotSiblingsForMovePreview() {
    guard let track = timelineProperties.dataSource.findTrack(containing: clip),
          track.engineTrackID != nil else {
      previewSiblingOriginals = [:]
      return
    }
    let snapshot = Dictionary(uniqueKeysWithValues:
      track.clips.lazy.filter { $0.id != clip.id }.map { ($0.id, $0.timeOffset) })
    previewSiblingOriginals = snapshot
    previewTrackSnapshots[track.id] = snapshot
  }

  private func clearPreviewShadowAndSnapshots() {
    for trackID in previewTrackSnapshots.keys {
      guard let track = findTrack(id: trackID) else { continue }
      for sibling in track.clips where sibling.previewTimeOffset != nil {
        sibling.clearPreviewTimeOffset()
      }
    }
    previewSiblingOriginals = [:]
    previewTrackSnapshots = [:]
  }

  private func snapshotTrackIfNeeded(_ track: Track) {
    guard previewTrackSnapshots[track.id] == nil else { return }
    previewTrackSnapshots[track.id] = Dictionary(
      uniqueKeysWithValues: track.clips
        .lazy
        .filter { $0.id != clip.id }
        .map { ($0.id, $0.timeOffset) },
    )
  }

  private func restoreTrackSnapshot(_ trackID: UUID) {
    guard let track = findTrack(id: trackID) else { return }
    for sibling in track.clips where sibling.id != clip.id {
      if sibling.previewTimeOffset != nil {
        sibling.clearPreviewTimeOffset()
      }
    }
  }

  /// `dataSource.tracks` doesn't include the background track, so plain lookups skip it.
  private func findTrack(id: UUID) -> Track? {
    let dataSource = timelineProperties.dataSource
    if let foreground = dataSource.tracks.first(where: { $0.id == id }) {
      return foreground
    }
    if dataSource.backgroundTrack.id == id {
      return dataSource.backgroundTrack
    }
    return nil
  }

  private func collectPreviewOffsets() -> [DesignBlockID: CMTime] {
    var offsets: [DesignBlockID: CMTime] = [:]
    for trackID in previewTrackSnapshots.keys {
      guard let track = findTrack(id: trackID) else { continue }
      for sibling in track.clips {
        if let preview = sibling.previewTimeOffset {
          offsets[sibling.id] = preview
        }
      }
    }
    return offsets
  }

  // MARK: - Preview + target resolution

  /// Pairs a resolved drop target with the absolute timeline position the drag snapped
  /// to (if any). Snap position is published to `timeline.snapIndicatorLinePositions`
  /// so the same dotted vertical line shown during trim appears here too.
  private struct DropResolution {
    let target: DropTarget
    let snapPosition: CMTime?
  }

  private func updateMoveDragDropPreview(proposedDelta: CMTime) {
    let draggedDuration = clip.duration ?? timeline.totalDuration - clip.timeOffset

    // Apply the scroll delta since drag start so the drop slot keeps tracking the
    // finger when horizontal auto-scroll moves the timeline underneath.
    let initialScrollOffset = timelineProperties.dragDropState.context?.initialScrollOffset ?? 0
    let currentScrollOffset = timelineProperties.horizontalScrollOffsetPoints
    let scrollDelta = timeline.convertToTime(points: currentScrollOffset - initialScrollOffset)
    let effectiveDelta = proposedDelta + scrollDelta

    offsetDelta = max(clip.timeOffset.imgly.makeNegative(), effectiveDelta)

    let pointerLocation = timelineProperties.dragDropState.context?.currentTouchLocation ?? .zero
    let grabOffsetX = timelineProperties.dragDropState.context?.grabOffsetX ?? 0
    let resolution = resolveDropTarget(
      pointerX: pointerLocation.x,
      pointerY: pointerLocation.y,
      grabOffsetX: grabOffsetX,
      draggedDuration: draggedDuration,
    )
    let newDropTarget = resolution?.target
    let newSnapPosition = resolution?.snapPosition

    let previousDropTarget: DropTarget? = if case let .dragging(context) = timelineProperties.dragDropState {
      context.dropTarget
    } else {
      nil
    }
    let previousTargetTrackID: UUID? = if case let .existingTrack(id, _, _, _) = previousDropTarget {
      id
    } else {
      nil
    }
    let newTargetTrackID: UUID? = if case let .existingTrack(id, _, _, _) = newDropTarget {
      id
    } else {
      nil
    }

    // Pointer crossed into a different track: clear the old preview, snapshot the new.
    if previousTargetTrackID != newTargetTrackID {
      if let previousTargetTrackID {
        restoreTrackSnapshot(previousTargetTrackID)
      }
      if let newTargetTrackID, let newTrack = findTrack(id: newTargetTrackID) {
        snapshotTrackIfNeeded(newTrack)
      }
    }

    if case let .existingTrack(trackID, insertIndex, dropStart, effectiveDuration) = newDropTarget,
       let track = findTrack(id: trackID) {
      applyCascade(
        in: track,
        insertIndex: insertIndex,
        dropStart: dropStart,
        draggedDuration: effectiveDuration ?? draggedDuration,
      )
    }

    if case var .dragging(context) = timelineProperties.dragDropState {
      context.dropTarget = newDropTarget
      timelineProperties.dragDropState = .dragging(context)
    }

    publishSnapAndHaptic(
      previousDropTarget: previousDropTarget,
      newDropTarget: newDropTarget,
      newSnapPosition: newSnapPosition,
    )
  }

  /// Updates `snapIndicatorLinePositions` and fires the snap haptic on a transition
  /// into a snap zone or onto a different drop slot.
  private func publishSnapAndHaptic(
    previousDropTarget: DropTarget?,
    newDropTarget: DropTarget?,
    newSnapPosition: CMTime?,
  ) {
    let previousSnapPositions = timeline.snapIndicatorLinePositions
    let newSnapPositions = newSnapPosition.map { [$0] } ?? []
    if previousSnapPositions != newSnapPositions {
      timeline.snapIndicatorLinePositions = newSnapPositions
      if !newSnapPositions.isEmpty {
        HapticsHelper.shared.timelineReorderSnap()
        return
      }
    }

    if shouldFireSnapHaptic(previous: previousDropTarget, new: newDropTarget) {
      HapticsHelper.shared.timelineReorderSnap()
    }
  }

  private func shouldFireSnapHaptic(previous: DropTarget?, new: DropTarget?) -> Bool {
    guard let previous, let new, previous != new else { return false }
    switch (previous, new) {
    case let (.existingTrack(pTrack, pIndex, _, _), .existingTrack(nTrack, nIndex, _, _)):
      return pTrack != nTrack || pIndex != nIndex
    case let (.newTrack(pAt, _), .newTrack(nAt, _)):
      return pAt != nAt
    default:
      return true
    }
  }

  /// Background clips reorder *within* the background track only — pointer Y is
  /// ignored, the slot is derived from pointer X. Foreground sources resolve to either
  /// an existing type-compatible track or a `.newTrack` zone in the gaps between rows.
  private struct DropCandidate {
    let track: Track
    let datasourceIndex: Int
    let frame: CGRect
  }

  private func resolveDropTarget(
    pointerX: CGFloat,
    pointerY: CGFloat,
    grabOffsetX: CGFloat,
    draggedDuration: CMTime,
  ) -> DropResolution? {
    let dataSource = timelineProperties.dataSource
    // Foreground rows live inside the vertical scroll view; the bg row is a
    // `.bottomLeading` overlay that doesn't clip them, so fg frames published under
    // the overlay would otherwise win on a naive maxY hit-test. Cap fg maxY at the
    // bg row's top so the bg overlay always wins below that line.
    let bgMinYCap = timelineProperties.trackFrames[dataSource.backgroundTrack.id]?.minY ?? .infinity

    if clip.isInBackgroundTrack {
      if let foregroundTarget = resolveForegroundRowHit(
        pointerX: pointerX,
        pointerY: pointerY,
        grabOffsetX: grabOffsetX,
        draggedDuration: draggedDuration,
      ) {
        return foregroundTarget
      }
      // Extend bg hit zone past `maxY` so fast drags that overshoot in one
      // frame still register, instead of falling through to the new-track zone.
      if let backgroundFrame = timelineProperties.trackFrames[dataSource.backgroundTrack.id],
         backgroundFrame.minY <= pointerY {
        return resolveBackgroundReorderTarget(
          pointerX: pointerX,
          grabOffsetX: grabOffsetX,
          draggedDuration: draggedDuration,
        )
      }
      if let newTrackTarget = resolveNewForegroundTrackForBackgroundSource(
        pointerX: pointerX,
        pointerY: pointerY,
        grabOffsetX: grabOffsetX,
      ) {
        return newTrackTarget
      }
      return resolveBackgroundReorderTarget(
        pointerX: pointerX,
        grabOffsetX: grabOffsetX,
        draggedDuration: draggedDuration,
      )
    }

    let candidates = collectForegroundDropCandidates()

    if let hit = candidates.first(where: {
      $0.frame.minY <= pointerY && pointerY <= min($0.frame.maxY, bgMinYCap)
    }) {
      guard let result = computeDropSlot(
        in: hit.track,
        trackFrame: hit.frame,
        pointerX: pointerX,
        grabOffsetX: grabOffsetX,
        draggedDuration: draggedDuration,
      ) else { return nil }
      return DropResolution(
        target: .existingTrack(
          trackID: hit.track.id,
          insertIndex: result.insertIndex,
          timeOffset: result.dropStart,
          effectiveDuration: result.effectiveDuration == draggedDuration ? nil : result.effectiveDuration,
        ),
        snapPosition: result.snapPosition,
      )
    }

    // Foreground → background drop: pointer at or below the bg row's top edge,
    // and the source type is allowed in the bg lane. Hit zone extends past
    // `maxY` to cover quick-drag overshoots.
    if clip.clipType.allowedInBackgroundTrack,
       let backgroundFrame = timelineProperties.trackFrames[dataSource.backgroundTrack.id],
       backgroundFrame.minY <= pointerY {
      return resolveBackgroundReorderTarget(
        pointerX: pointerX,
        grabOffsetX: grabOffsetX,
        draggedDuration: draggedDuration,
      )
    }

    guard !candidates.isEmpty else { return nil }

    return resolveNewTrackZoneTarget(
      candidates: candidates,
      pointerX: pointerX,
      pointerY: pointerY,
      grabOffsetX: grabOffsetX,
      draggedDuration: draggedDuration,
    )
  }

  /// Returns a foreground-row drop target when the pointer is inside a
  /// type-compatible fg row, with the bg-overlay maxY cap applied.
  private func resolveForegroundRowHit(
    pointerX: CGFloat,
    pointerY: CGFloat,
    grabOffsetX: CGFloat,
    draggedDuration: CMTime,
  ) -> DropResolution? {
    let dataSource = timelineProperties.dataSource
    let frames = timelineProperties.trackFrames
    let bgMinYCap = frames[dataSource.backgroundTrack.id]?.minY ?? .infinity
    for track in dataSource.tracks {
      guard track !== dataSource.backgroundTrack,
            isTypeCompatible(target: track),
            let frame = frames[track.id],
            frame.minY <= pointerY, pointerY <= min(frame.maxY, bgMinYCap) else { continue }
      guard let result = computeDropSlot(
        in: track,
        trackFrame: frame,
        pointerX: pointerX,
        grabOffsetX: grabOffsetX,
        draggedDuration: draggedDuration,
      ) else { continue }
      return DropResolution(
        target: .existingTrack(
          trackID: track.id,
          insertIndex: result.insertIndex,
          timeOffset: result.dropStart,
          effectiveDuration: result.effectiveDuration == draggedDuration ? nil : result.effectiveDuration,
        ),
        snapPosition: result.snapPosition,
      )
    }
    return nil
  }

  /// New-fg-track drop target for a bg-source drag landing in a gap between rows.
  /// Filters by audio/visual lane so the indicator matches `refreshTimeline`'s sort.
  private func resolveNewForegroundTrackForBackgroundSource(
    pointerX: CGFloat,
    pointerY: CGFloat,
    grabOffsetX: CGFloat,
  ) -> DropResolution? {
    let dataSource = timelineProperties.dataSource
    let frames = timelineProperties.trackFrames

    let candidates: [DropCandidate] = dataSource.tracks
      .enumerated()
      .compactMap { idx, track in
        guard track !== dataSource.backgroundTrack,
              isTypeCompatible(target: track),
              let frame = frames[track.id] else { return nil }
        return DropCandidate(track: track, datasourceIndex: idx, frame: frame)
      }
    let sortedByY = candidates.sorted { $0.frame.minY < $1.frame.minY }

    let referenceFrame: CGRect? = sortedByY.first?.frame ?? frames[dataSource.backgroundTrack.id]
    guard let referenceFrame else { return nil }
    let dropTime = max(.zero, timeline.convertToTime(points: pointerX - referenceFrame.minX - grabOffsetX))

    guard let first = sortedByY.first, let last = sortedByY.last else {
      return DropResolution(target: .newTrack(insertAt: 0, timeOffset: dropTime), snapPosition: nil)
    }
    if pointerY < first.frame.minY {
      return DropResolution(
        target: .newTrack(insertAt: dataSource.tracks.count, timeOffset: dropTime),
        snapPosition: nil,
      )
    }
    if pointerY > last.frame.maxY {
      return DropResolution(
        target: .newTrack(insertAt: last.datasourceIndex, timeOffset: dropTime),
        snapPosition: nil,
      )
    }
    for (upper, lower) in zip(sortedByY, sortedByY.dropFirst()) {
      if pointerY > upper.frame.maxY, pointerY < lower.frame.minY {
        return DropResolution(
          target: .newTrack(insertAt: upper.datasourceIndex, timeOffset: dropTime),
          snapPosition: nil,
        )
      }
    }
    return nil
  }

  private func collectForegroundDropCandidates() -> [DropCandidate] {
    let dataSource = timelineProperties.dataSource
    let frames = timelineProperties.trackFrames
    var candidates: [DropCandidate] = []
    for (idx, track) in dataSource.tracks.enumerated() {
      guard track !== dataSource.backgroundTrack,
            isTypeCompatible(target: track),
            let frame = frames[track.id] else { continue }
      candidates.append(DropCandidate(track: track, datasourceIndex: idx, frame: frame))
    }
    return candidates
  }

  /// Pointer is in a gap. Resolves to `.newTrack`, except solo-source-adjacent zones
  /// fall back to the nearest existing track (otherwise the drop would be a no-op move).
  private func resolveNewTrackZoneTarget(
    candidates: [DropCandidate],
    pointerX: CGFloat,
    pointerY: CGFloat,
    grabOffsetX: CGFloat,
    draggedDuration: CMTime,
  ) -> DropResolution? {
    let sortedByY = candidates.sorted { $0.frame.minY < $1.frame.minY }
    guard let firstByY = sortedByY.first, let lastByY = sortedByY.last else { return nil }
    // No sibling track to anchor against, so derive `dropTime` from the pointer
    // directly — same shape as `computeDropSlot`.
    let dropTime = max(.zero, timeline.convertToTime(points: pointerX - firstByY.frame.minX - grabOffsetX))

    let sourceTrackID = timelineProperties.dragDropState.context?.sourceTrackID
    let dataSource = timelineProperties.dataSource
    let sourceTrack = dataSource.tracks.first { $0.id == sourceTrackID }
    let sourceIsSolo = sourceTrack?.clips.count == 1

    let fallbackToNearest: () -> DropResolution? = {
      self.nearestExistingTrackDropTarget(
        candidates: candidates,
        pointerX: pointerX,
        pointerY: pointerY,
        grabOffsetX: grabOffsetX,
        draggedDuration: draggedDuration,
      )
    }

    if pointerY < firstByY.frame.minY {
      if sourceIsSolo, firstByY.track.id == sourceTrackID {
        return fallbackToNearest()
      }
      return DropResolution(
        target: .newTrack(insertAt: dataSource.tracks.count, timeOffset: dropTime),
        snapPosition: nil,
      )
    }

    if pointerY > lastByY.frame.maxY {
      if sourceIsSolo, lastByY.track.id == sourceTrackID {
        return fallbackToNearest()
      }
      return DropResolution(
        target: .newTrack(insertAt: lastByY.datasourceIndex, timeOffset: dropTime),
        snapPosition: nil,
      )
    }

    for i in 0 ..< (sortedByY.count - 1) {
      let upper = sortedByY[i]
      let lower = sortedByY[i + 1]
      guard pointerY > upper.frame.maxY, pointerY < lower.frame.minY else { continue }
      let sourceAdjacent = upper.track.id == sourceTrackID || lower.track.id == sourceTrackID
      if sourceIsSolo, sourceAdjacent {
        return fallbackToNearest()
      }
      return DropResolution(target: .newTrack(insertAt: upper.datasourceIndex, timeOffset: dropTime), snapPosition: nil)
    }

    return fallbackToNearest()
  }

  private func nearestExistingTrackDropTarget(
    candidates: [DropCandidate],
    pointerX: CGFloat,
    pointerY: CGFloat,
    grabOffsetX: CGFloat,
    draggedDuration: CMTime,
  ) -> DropResolution? {
    guard let nearest = candidates.min(by: { a, b in
      let distA = max(0, max(a.frame.minY - pointerY, pointerY - a.frame.maxY))
      let distB = max(0, max(b.frame.minY - pointerY, pointerY - b.frame.maxY))
      return distA < distB
    }) else { return nil }
    guard let result = computeDropSlot(
      in: nearest.track,
      trackFrame: nearest.frame,
      pointerX: pointerX,
      grabOffsetX: grabOffsetX,
      draggedDuration: draggedDuration,
    ) else { return nil }
    return DropResolution(
      target: .existingTrack(
        trackID: nearest.track.id,
        insertIndex: result.insertIndex,
        timeOffset: result.dropStart,
        effectiveDuration: result.effectiveDuration == draggedDuration ? nil : result.effectiveDuration,
      ),
      snapPosition: result.snapPosition,
    )
  }

  private func resolveBackgroundReorderTarget(
    pointerX: CGFloat,
    grabOffsetX: CGFloat,
    draggedDuration: CMTime,
  ) -> DropResolution? {
    let backgroundTrack = timelineProperties.dataSource.backgroundTrack
    guard let trackFrame = timelineProperties.trackFrames[backgroundTrack.id] else { return nil }
    guard let result = computeDropSlot(
      in: backgroundTrack,
      trackFrame: trackFrame,
      pointerX: pointerX,
      grabOffsetX: grabOffsetX,
      draggedDuration: draggedDuration,
    ) else { return nil }
    // Background tracks auto-pack on commit, so the indicator should land at the
    // packed position for `insertIndex` rather than the unconstrained pointer-derived
    // dropStart — otherwise the user sees a gap that disappears on release.
    let packedDropStart = backgroundTrack.clips
      .filter { $0.id != clip.id }
      .sorted { $0.timeOffset < $1.timeOffset }
      .prefix(result.insertIndex)
      .compactMap(\.duration)
      .reduce(CMTime.zero, +)
    return DropResolution(
      target: .existingTrack(
        trackID: backgroundTrack.id,
        insertIndex: result.insertIndex,
        timeOffset: packedDropStart,
        effectiveDuration: result.effectiveDuration == draggedDuration ? nil : result.effectiveDuration,
      ),
      snapPosition: nil,
    )
  }

  private func isTypeCompatible(target: Track) -> Bool {
    guard let example = target.clips.first else { return true }
    let draggedIsAudioLike = clip.clipType == .audio || clip.clipType == .voiceOver
    let targetIsAudioLike = example.clipType == .audio || example.clipType == .voiceOver
    return draggedIsAudioLike == targetIsAudioLike
  }

  /// Resolved slot for a drop. `effectiveDuration` differs from the dragged clip's
  /// duration only when the slot's too small and the tail must be trimmed to fit.
  private struct DropSlot {
    let insertIndex: Int
    let dropStart: CMTime
    let effectiveDuration: CMTime
    let snapPosition: CMTime?
  }

  /// Same floor as the trim handle, so dropping into a tight slot can't produce a
  /// shorter clip than dragging a trim handle would.
  private var minTrimmedDuration: CMTime {
    configuration.minClipDuration
  }

  /// Walls bounding the drop slot and the cumulative duration of unlocked predecessors
  /// the cascade has to pack against `lockedPredecessorWall`. `.positiveInfinity` /
  /// `.zero` when there's no locked wall on the corresponding side.
  private struct LockedWalls {
    let lockedSuccessorWall: CMTime
    let lockedPredecessorWall: CMTime
    let unlockedBefore: CMTime
  }

  /// Flips the slot when the finger crosses a sibling's centre, so long clips don't
  /// have to overshoot by half their own duration before the slot changes.
  private func resolveInsertIndex(
    others: [(clip: Clip, originalStart: CMTime)],
    pointerTime: CMTime,
  ) -> Int {
    for (i, entry) in others.enumerated() {
      guard let otherDur = entry.clip.duration else { continue }
      let otherMid = entry.originalStart + CMTime(seconds: otherDur.seconds / 2)
      if pointerTime < otherMid {
        return i
      }
    }
    return others.count
  }

  /// Walks both directions from `insertIndex` to find the locked-clip walls and tally
  /// the unlocked predecessors that the cascade will need to pack against the
  /// predecessor wall.
  private func resolveLockedWalls(
    others: [(clip: Clip, originalStart: CMTime)],
    insertIndex: Int,
  ) -> LockedWalls {
    var unlockedAfter = CMTime.zero
    var lockedSuccessorWall: CMTime = .positiveInfinity
    for entry in others[insertIndex...] {
      if entry.clip.isLocked {
        lockedSuccessorWall = entry.originalStart - unlockedAfter
        break
      }
      // swiftlint:disable:next shorthand_operator
      unlockedAfter = unlockedAfter + (entry.clip.duration ?? .zero)
    }

    var lockedPredecessorWall = CMTime.zero
    var unlockedBefore = CMTime.zero
    for entry in others[..<insertIndex].reversed() {
      if entry.clip.isLocked {
        lockedPredecessorWall = entry.originalStart + (entry.clip.duration ?? .zero)
        break
      }
      // swiftlint:disable:next shorthand_operator
      unlockedBefore = unlockedBefore + (entry.clip.duration ?? .zero)
    }

    return LockedWalls(
      lockedSuccessorWall: lockedSuccessorWall,
      lockedPredecessorWall: lockedPredecessorWall,
      unlockedBefore: unlockedBefore,
    )
  }

  /// `insertIndex` is decided by the finger's time position; `dropStart` still derives
  /// from the dragged clip's leading edge (`pointer - grabOffsetX`) so the floating
  /// overlay stays glued to the finger. `snapPosition` feeds `snapIndicatorLinePositions`.
  /// Returns `nil` when locked walls leave a gap below `minTrimmedDuration`, or when
  /// the gap is smaller than `draggedDuration` and the clip isn't trimmable — caller
  /// treats `nil` as "reject the drop" so the clip snaps back to its origin.
  private func computeDropSlot(
    in track: Track,
    trackFrame: CGRect,
    pointerX: CGFloat,
    grabOffsetX: CGFloat,
    draggedDuration: CMTime,
  ) -> DropSlot? {
    let snapshot = previewTrackSnapshots[track.id] ?? [:]
    let othersByOriginalStart: [(clip: Clip, originalStart: CMTime)] = track.clips
      .filter { $0.id != clip.id }
      .map { ($0, snapshot[$0.id] ?? $0.timeOffset) }
      .sorted { $0.originalStart < $1.originalStart }

    let desiredDropStart = timeline.convertToTime(points: pointerX - trackFrame.minX - grabOffsetX)
    let pointerTime = timeline.convertToTime(points: pointerX - trackFrame.minX)
    let insertIndex = resolveInsertIndex(
      others: othersByOriginalStart,
      pointerTime: pointerTime,
    )

    let prev = insertIndex > 0 ? othersByOriginalStart[insertIndex - 1] : nil
    let next = insertIndex < othersByOriginalStart.count
      ? othersByOriginalStart[insertIndex]
      : nil

    let prevEnd = prev.map { $0.originalStart + ($0.clip.duration ?? .zero) } ?? .zero
    let slotHasEnoughRoom: Bool = if let next {
      next.originalStart - prevEnd >= draggedDuration
    } else {
      true
    }

    let walls = resolveLockedWalls(others: othersByOriginalStart, insertIndex: insertIndex)

    // Decide the slot kind: free placement when there's enough room *and* no locked
    // successor squeezes the cascade; otherwise try pull + trim.
    let nextCap = next.map { $0.originalStart - draggedDuration } ?? .positiveInfinity
    let cap = min(nextCap, walls.lockedSuccessorWall - draggedDuration)
    let canPlaceFreely = slotHasEnoughRoom && cap >= prevEnd

    let lowerBound: CMTime
    let upperBound: CMTime
    let effectiveDuration: CMTime
    let unsnappedDropStart: CMTime
    if canPlaceFreely {
      lowerBound = prevEnd
      upperBound = cap
      effectiveDuration = draggedDuration
      unsnappedDropStart = max(lowerBound, min(upperBound, max(.zero, desiredDropStart)))
    } else {
      // Pull unlocked predecessors leftward against `lockedPredecessorWall` and push
      // unlocked successors rightward against `lockedSuccessorWall`. Trim if the
      // combined space is still smaller than the dragged duration; reject if it's
      // smaller than `minTrimmedDuration`.
      let pulledLowerBound = walls.lockedPredecessorWall + walls.unlockedBefore
      guard let resolved = trimToFit(
        lowerBound: pulledLowerBound,
        lockedSuccessorWall: walls.lockedSuccessorWall,
        draggedDuration: draggedDuration,
      ) else { return nil }
      lowerBound = resolved.lowerBound
      upperBound = resolved.upperBound
      effectiveDuration = resolved.effectiveDuration
      unsnappedDropStart = resolved.dropStart
    }

    let (dropStart, snapPosition) = applyDropSnap(
      unsnappedDropStart: unsnappedDropStart,
      draggedDuration: effectiveDuration,
      lowerBound: lowerBound,
      upperBound: upperBound,
    )
    return DropSlot(
      insertIndex: insertIndex,
      dropStart: dropStart,
      effectiveDuration: effectiveDuration,
      snapPosition: snapPosition,
    )
  }

  private struct TrimToFitResult {
    let lowerBound: CMTime
    let upperBound: CMTime
    let effectiveDuration: CMTime
    let dropStart: CMTime
  }

  /// Cascade-too-tight case: pin drop start to `lowerBound` and trim the tail to fit
  /// against `lockedSuccessorWall`. Rejects (returns `nil`) below `minTrimmedDuration`,
  /// or for live-buffer recordings whose duration is owned by the buffer.
  /// Non-trimmable clips with freely-settable duration (shape / image / text) pass
  /// through — the interactor's `setTrim` falls back to `setDuration` for those.
  private func trimToFit(
    lowerBound: CMTime,
    lockedSuccessorWall: CMTime,
    draggedDuration: CMTime,
  ) -> TrimToFitResult? {
    let availableRoom = lockedSuccessorWall - lowerBound
    guard availableRoom >= minTrimmedDuration else { return nil }
    let effectiveDuration: CMTime
    if availableRoom < draggedDuration {
      guard !isLiveBufferRecording else { return nil }
      effectiveDuration = availableRoom
    } else {
      effectiveDuration = draggedDuration
    }
    return TrimToFitResult(
      lowerBound: lowerBound,
      upperBound: lowerBound,
      effectiveDuration: effectiveDuration,
      dropStart: lowerBound,
    )
  }

  /// Live-buffer audio (voice-overs in progress) can't be tail-shortened — the
  /// duration is owned by the buffer length, not editable.
  private var isLiveBufferRecording: Bool {
    (clip.clipType == .audio || clip.clipType == .voiceOver)
      && (clip.footageURLString?.hasPrefix("buffer://") == true)
  }

  /// Mirrors `TimelineDataSource.updateSnapDetents` but skips the dragged clip's own
  /// edges so back-to-back neighbours sharing a boundary still contribute a snap
  /// target. (Filtering the deduplicated `dataSource.snapDetents` by value would
  /// remove the neighbour's edge along with the dragged clip's.)
  private func snapDetentsExcludingDraggedClip() -> [CMTime] {
    let dataSource = timelineProperties.dataSource
    var detents: [CMTime] = [.zero]
    var bgCursor = CMTime.zero
    for bgClip in dataSource.backgroundTrack.clips {
      guard let duration = bgClip.duration else { continue }
      // swiftlint:disable:next shorthand_operator
      bgCursor = bgCursor + duration
      if bgClip.id != clip.id, !detents.contains(bgCursor) {
        detents.append(bgCursor)
      }
    }
    for fgClip in dataSource.foregroundClips() where fgClip.id != clip.id {
      let start = fgClip.timeOffset
      if !detents.contains(start) {
        detents.append(start)
      }
      if let duration = fgClip.duration {
        let end = start + duration
        if !detents.contains(end) {
          detents.append(end)
        }
      }
    }
    let playhead = timelineProperties.player.playheadPosition
    if !detents.contains(playhead) {
      detents.append(playhead)
    }
    return detents
  }

  /// Mirrors the trim's snap-detent behaviour: the leading or trailing edge of the
  /// drop slot snaps to the nearest in-range detent (background clip ends, foreground
  /// clip edges, playhead) within ~5pt of finger travel, so users get the same dotted
  /// vertical line cue while dragging.
  private func applyDropSnap(
    unsnappedDropStart: CMTime,
    draggedDuration: CMTime,
    lowerBound: CMTime,
    upperBound: CMTime,
  ) -> (dropStart: CMTime, snapPosition: CMTime?) {
    let snapTolerance = timeline.convertToTime(points: 5)
    let detents = snapDetentsExcludingDraggedClip()

    var bestDistance = snapTolerance
    var snappedDropStart: CMTime?
    var snapPosition: CMTime?
    for detent in detents {
      // Try snapping the leading edge to the detent.
      let leadingCandidate = max(lowerBound, min(upperBound, detent))
      if leadingCandidate == detent {
        let distance = CMTime(seconds: abs((unsnappedDropStart - leadingCandidate).seconds))
        if distance < bestDistance {
          bestDistance = distance
          snappedDropStart = leadingCandidate
          snapPosition = detent
        }
      }
      // Try snapping the trailing edge.
      let trailingCandidate = max(lowerBound, min(upperBound, detent - draggedDuration))
      if trailingCandidate + draggedDuration == detent {
        let distance = CMTime(seconds: abs((unsnappedDropStart - trailingCandidate).seconds))
        if distance < bestDistance {
          bestDistance = distance
          snappedDropStart = trailingCandidate
          snapPosition = detent
        }
      }
    }
    return (snappedDropStart ?? unsnappedDropStart, snapPosition)
  }

  /// Previews where the dragged clip would land. The background track packs
  /// from 0 (engine auto-packs); foreground tracks preserve snapshot positions.
  /// Locked siblings are walls.
  private func applyCascade(
    in track: Track,
    insertIndex: Int,
    dropStart: CMTime,
    draggedDuration: CMTime,
  ) {
    let snapshot = previewTrackSnapshots[track.id] ?? [:]
    let othersByOriginalStart: [(clip: Clip, originalStart: CMTime)] = track.clips
      .filter { $0.id != clip.id }
      .map { ($0, snapshot[$0.id] ?? $0.timeOffset) }
      .sorted { $0.originalStart < $1.originalStart }

    let isBackgroundTrack = track === timelineProperties.dataSource.backgroundTrack

    // We pull unlocked predecessors leftward only when the dragged clip's drop start
    // sits earlier than the immediate predecessor's original end — i.e. the dragged
    // clip needs that slack to fit. When there's already room ahead we leave them in
    // place so the user doesn't see surprise repositioning of nearby clips.
    let originalPrevEnd: CMTime = {
      guard insertIndex > 0 else { return .zero }
      let prev = othersByOriginalStart[insertIndex - 1]
      return prev.originalStart + (prev.clip.duration ?? .zero)
    }()
    let needsPredecessorPull = dropStart < originalPrevEnd

    var beforeCursor = CMTime.zero
    for i in 0 ..< insertIndex {
      let entry = othersByOriginalStart[i]
      let target: CMTime = if entry.clip.isLocked {
        // Locked predecessor — stays at authored position. Cursor jumps to its end so
        // any unlocked siblings that follow pack against it, not the prior cursor.
        entry.originalStart
      } else if isBackgroundTrack || needsPredecessorPull {
        // Pack against the cumulative cursor (= against the nearest locked wall, or 0).
        beforeCursor
      } else {
        entry.originalStart
      }
      if entry.clip.displayTimeOffset != target {
        entry.clip.applyPreview(timeOffset: target)
      }
      beforeCursor = target + (entry.clip.duration ?? .zero)
    }
    var cursor = dropStart + draggedDuration
    for i in insertIndex ..< othersByOriginalStart.count {
      let entry = othersByOriginalStart[i]
      if entry.clip.isLocked {
        // Locked wall.
        if entry.clip.displayTimeOffset != entry.originalStart {
          entry.clip.applyPreview(timeOffset: entry.originalStart)
        }
        cursor = entry.originalStart + (entry.clip.duration ?? .zero)
        continue
      }
      let newStart = max(entry.originalStart, cursor)
      if entry.clip.displayTimeOffset != newStart {
        entry.clip.applyPreview(timeOffset: newStart)
      }
      cursor = newStart + (entry.clip.duration ?? .zero)
    }
  }
}
