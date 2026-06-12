import CoreMedia
import IMGLYCamera
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEngine
import SwiftUI

extension Interactor: TimelineInteractor {
  /// Configure the timeline.
  func configureTimeline() throws {
    guard let engine else { return }

    guard let page = try engine.scene.getCurrentPage() else {
      throw Error(errorDescription: "Page missing")
    }

    timelineProperties.currentPage = page

    timelineProperties.thumbnailsManager.interactor = self
    timelineProperties.timeline = Timeline(interactor: self, configuration: timelineProperties.configuration)

    refreshTimeline()
    updateDurations()
    observeAppLifecycle()
  }

  private func observeAppLifecycle() {
    NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        guard let self else { return }
        if isVoiceOverRecordModeRecording {
          Task { [weak self] in
            await self?.finishVoiceOverRecordMode()
          }
        } else {
          pauseIfNeeded()
        }
      }
      .store(in: &cancellables)
  }

  func createBackgroundTrackIfNeeded() {
    guard let engine,
          timelineProperties.backgroundTrack == nil,
          let pageID = timelineProperties.currentPage else { return }
    do {
      // Create the Background Track if it doesn't exist yet
      let backgroundTrack = try engine.block.create(DesignBlockType.track)
      try engine.block.appendChild(to: pageID, child: backgroundTrack)
      try engine.block.setAlwaysOnBottom(backgroundTrack, enabled: true)
      try engine.block.fillParent(backgroundTrack)
      try engine.block.setScopeEnabled(backgroundTrack, scope: .key(.editorSelect), enabled: false)
      if try engine.block.supportsPageDurationSource(pageID, id: backgroundTrack) {
        try engine.block.setPageDurationSource(pageID, id: backgroundTrack)
      }
      timelineProperties.backgroundTrack = backgroundTrack
      timelineProperties.dataSource.backgroundTrack.engineTrackID = backgroundTrack
    } catch {
      handleError(error)
    }
  }

  /// Cleans up empty tracks to prevent clutter in the timeline.
  private func cleanUpEmptyTracks() {
    guard let engine,
          let page = timelineProperties.currentPage else { return }
    do {
      let children = try engine.block.getChildren(page)
      for block in children where engine.block.isValid(block) {
        let type = try engine.block.getType(block)
        if type == DesignBlockType.track.rawValue || type == DesignBlockType.captionTrack.rawValue,
           try engine.block.getChildren(block).isEmpty {
          // Clear background track reference if we're destroying it
          if block == timelineProperties.backgroundTrack {
            timelineProperties.backgroundTrack = nil
          }
          try engine.block.destroy(block)
        }
      }
    } catch {
      handleError(error)
    }
  }

  // swiftlint:disable cyclomatic_complexity
  /// Updates the timeline. Called on every change from the engine events subscription.
  func updateTimeline(_ events: [BlockEvent]) {
    guard let engine,
          !timelineProperties.isScrubbing,
          let page = timelineProperties.currentPage else { return }

    cleanUpEmptyTracks()

    // If the events list contains only the page and we're currently playing back, we can skip evaluating the events,
    // because it's most likely only the update of the playback position
    if timelineProperties.player.isPlaying,
       events.count == 1, events.first?.block == page {
      return
    }

    var isDirty = false

    // Check if the block order has changed.
    // This also catches .created and .destroyed blocks, but only for direct children of the page.
    if let blockOrder = try? engine.block.getChildren(page),
       blockOrder != timelineProperties.blockOrder {
      isDirty = true
      timelineProperties.blockOrder = blockOrder
    }

    if events.contains(where: { $0.type == .created }) {
      isDirty = true
    }

    if events.contains(where: { $0.type == .destroyed }) {
      guard !events.contains(where: { $0.block == timelineProperties.scrubbingPreviewLayer }) else {
        // If this event was triggered by deleting the scrubbing preview layer, ignore.
        timelineProperties.scrubbingPreviewLayer = nil
        return
      }
      isDirty = true
      for event in events.compactMap({ $0.type == .destroyed ? $0 : nil }) {
        timelineProperties.thumbnailsManager.destroyProvider(id: event.block)
      }
    }

    if isDirty {
      // Skip the async follow-up if `applyDrop` already refreshed; the duplicate
      // rebuild flashes an empty-state frame.
      if timelineProperties.suppressNextDirtyRefresh {
        timelineProperties.suppressNextDirtyRefresh = false
        updateDurations()
        return
      }
      refreshTimeline()
      updateDurations()
      return
    }

    if events.contains(where: { $0.type == .updated }) {
      var clipsToUpdate = Set<Clip>()

      for event in events {
        guard event.type == .updated else { continue }
        if let clip = timelineProperties.dataSource.findClip(containing: event.block) {
          clipsToUpdate.insert(clip)
        }
      }
      for clip in clipsToUpdate {
        refresh(clip: clip)
      }
      // Once per batch — reading page duration triggers `Track::layout()`, which
      // amplifies its gap-handling bug on intermediate state.
      updateDurations()
    }
  }

  // swiftlint:enable cyclomatic_complexity

  /// Updates the play/pause state from the engine state.
  func updatePlaybackState() {
    guard let engine,
          let pageID = timelineProperties.currentPage else { return }

    let isPlaying = (try? engine.block.isPlaying(pageID)) ?? false
    if isPlaying != timelineProperties.player.isPlaying {
      timelineProperties.player.isPlaying = isPlaying
    }

    guard let seconds = try? engine.block.getPlaybackTime(pageID) else { return }

    let position = CMTime(seconds: seconds)
    if let maxDuration = timelineProperties.player.maxPlaybackDuration,
       position > maxDuration {
      let resolvedPosition: CMTime
      if isPlaying {
        if isLoopingPlaybackEnabled {
          resolvedPosition = CMTime(seconds: 0)
          setPlayheadPosition(resolvedPosition)
        } else {
          pause()
          timelineProperties.player.isPlaying = false
          resolvedPosition = maxDuration
          setPlayheadPosition(resolvedPosition)
        }
      } else {
        resolvedPosition = maxDuration
        setPlayheadPosition(resolvedPosition)
      }
      timelineProperties.player.playheadPosition = resolvedPosition
      return
    }
    if position != timelineProperties.player.playheadPosition {
      timelineProperties.player.playheadPosition = position
    }
  }

  // MARK: Duration Constraints

  func setVideoDurationConstraints(
    minimumDuration: TimeInterval?,
    maximumDuration: TimeInterval?,
  ) {
    let constraints = VideoDurationConstraints(
      minimumDuration: minimumDuration,
      maximumDuration: maximumDuration,
    ).normalized()
    timelineProperties.videoDurationConstraints = constraints
    timelineProperties.player.maxPlaybackDuration = constraints.maximumTime

    if let maxDuration = constraints.maximumTime,
       timelineProperties.player.playheadPosition > maxDuration {
      setPlayheadPosition(maxDuration)
      timelineProperties.player.playheadPosition = maxDuration
    }
  }

  // MARK: Drag & Drop

  /// `insertChild` runs before `setTimeOffset` so `Track::layout()` walks children in
  /// time order — its gap-handling bug corrupts intermediate state otherwise.
  /// Cross-track and new-track drops refresh synchronously to rebuild track membership.
  func applyDrop(clip: Clip, target: DropTarget, siblingOffsets: [DesignBlockID: CMTime]) {
    guard let engine else { return }
    switch target {
    case let .newTrack(insertAt, timeOffset):
      applyNewTrackDrop(engine: engine, clip: clip, insertAt: insertAt, timeOffset: timeOffset)
    case let .existingTrack(trackID, insertIndex, timeOffset, effectiveDuration):
      applyExistingTrackDrop(
        engine: engine,
        clip: clip,
        trackID: trackID,
        insertIndex: insertIndex,
        timeOffset: timeOffset,
        effectiveDuration: effectiveDuration,
        siblingOffsets: siblingOffsets,
      )
    }
  }

  private func applyExistingTrackDrop(
    engine: Engine,
    clip: Clip,
    trackID: UUID,
    insertIndex: Int,
    timeOffset: CMTime,
    effectiveDuration: CMTime?,
    siblingOffsets: [DesignBlockID: CMTime],
  ) {
    let dataSource = timelineProperties.dataSource
    let targetTrack: Track
    if let foreground = dataSource.tracks.first(where: { $0.id == trackID }) {
      targetTrack = foreground
    } else if trackID == dataSource.backgroundTrack.id {
      targetTrack = dataSource.backgroundTrack
    } else {
      return
    }
    let sourceTrack = dataSource.findTrack(containing: clip)
    let isCrossTrack = sourceTrack?.id != targetTrack.id
    let isBackgroundReorder = targetTrack === dataSource.backgroundTrack
    let sourceWasBackground = sourceTrack === dataSource.backgroundTrack
    do {
      // Trim-to-fit (tail only): shrink the engine duration *before* repositioning so
      // `Track::layout()` doesn't see an oversized clip overlapping a locked sibling
      // and bump the locked sibling out of place. `trimOffset` is left alone.
      if let effectiveDuration {
        try applyTailTrimDuration(engine: engine, clip: clip, duration: effectiveDuration)
      }

      if isBackgroundReorder {
        try insertIntoBackgroundTrack(engine: engine, clip: clip, insertIndex: insertIndex)
        if !sourceWasBackground {
          try resetCropAndFillParentForBackgroundDrop(engine: engine, clipID: clip.id)
        }
      } else if let targetEngineTrackID = targetTrack.engineTrackID {
        try insertIntoMultiClipTrack(
          engine: engine,
          clip: clip,
          targetTrack: targetTrack,
          engineTrackID: targetEngineTrackID,
          insertIndex: insertIndex,
          timeOffset: timeOffset,
          siblingOffsets: siblingOffsets,
        )
      } else if isCrossTrack {
        // Standalone target — promote into a multi-clip track wrapping both clips.
        try promoteStandaloneTargetAndInsert(
          engine: engine,
          clip: clip,
          targetTrack: targetTrack,
          insertIndex: insertIndex,
          timeOffset: timeOffset,
          siblingOffsets: siblingOffsets,
        )
      } else {
        // Same standalone track — just move it.
        try engine.block.setTimeOffset(clip.id, offset: timeOffset.seconds)
      }

      addUndoStep()
      finalizeExistingTrackDrop(
        clip: clip,
        targetTrack: targetTrack,
        isCrossTrack: isCrossTrack,
        sourceWasBackground: sourceWasBackground,
      )
    } catch {
      handleError(error)
    }
  }

  /// Mirrors `setDuration` from the trim path: writes the new clip duration plus, for
  /// video / audio, the matching trim-length on the underlying media so the engine
  /// stays internally consistent. Used by trim-to-fit drops where we shrink the tail
  /// before repositioning.
  private func applyTailTrimDuration(engine: Engine, clip: Clip, duration: CMTime) throws {
    try engine.block.setDuration(clip.id, duration: duration.seconds)
    if clip.clipType == .audio {
      try engine.block.setTrimLength(clip.id, length: duration.seconds)
    } else if clip.clipType == .video, let fillID = clip.fillID {
      try engine.block.setTrimLength(fillID, length: duration.seconds)
    }
  }

  /// No `setTimeOffset` — the engine auto-packs bg offsets on insert. Canvas
  /// geometry is handled separately by `resetCropAndFillParentForBackgroundDrop`.
  private func insertIntoBackgroundTrack(engine: Engine, clip: Clip, insertIndex: Int) throws {
    guard let backgroundTrackID = syncAndResolveBackgroundTrackID(engine: engine, createIfNeeded: true) else { return }
    try engine.block.insertChild(into: backgroundTrackID, child: clip.id, at: insertIndex)
  }

  /// Mirrors the `moveAsClip` handler: when a clip lands in the background track
  /// from outside, reset its crop and `fillParent` so it covers the page — except
  /// for stickers, which keep their authored geometry.
  private func resetCropAndFillParentForBackgroundDrop(engine: Engine, clipID: DesignBlockID) throws {
    guard try engine.block.isScopeEnabled(clipID, scope: .key(.layerCrop)),
          try engine.block.getKind(clipID) != BlockKindKey.sticker.rawValue else { return }
    try engine.block.resetCrop(clipID)
    try engine.block.fillParent(clipID)
  }

  /// `timelineProperties.backgroundTrack` and `dataSource.backgroundTrack.engineTrackID`
  /// can diverge, so consult both before falling back to creation. `createIfNeeded`
  /// defaults to `false` so post-drop callers can't resurrect a track that
  /// `cleanUpEmptyTracks` just destroyed.
  private func syncAndResolveBackgroundTrackID(engine: Engine, createIfNeeded: Bool = false) -> DesignBlockID? {
    if let id = timelineProperties.backgroundTrack, engine.block.isValid(id) {
      return id
    }
    if let id = timelineProperties.dataSource.backgroundTrack.engineTrackID,
       engine.block.isValid(id) {
      // Keep `timelineProperties.backgroundTrack` in sync — future callers rely on it.
      timelineProperties.backgroundTrack = id
      return id
    }
    guard createIfNeeded else { return nil }
    createBackgroundTrackIfNeeded()
    if let id = timelineProperties.backgroundTrack, engine.block.isValid(id) {
      return id
    }
    return nil
  }

  /// Walks the background track's remaining children in order and writes
  /// packed offsets (0, d₀, d₀+d₁, …). Used after a cross-track drop that
  /// removed a clip from the background: the engine's auto-pack only runs on
  /// insert, so without this call the remaining children keep their pre-drag
  /// offsets and end up rendering past the page duration.
  ///
  /// Ordering: must run AFTER `cleanUpEmptyTracks()` and BEFORE
  /// `refreshTimeline()`. The `createIfNeeded: false` default in
  /// `syncAndResolveBackgroundTrackID` defends against the cleanup step
  /// destroying the bg track first.
  private func packBackgroundChildren(engine: Engine) {
    guard let backgroundTrackID = syncAndResolveBackgroundTrackID(engine: engine) else { return }
    do {
      var cursor: Double = 0
      for childID in try engine.block.getChildren(backgroundTrackID) {
        try engine.block.setTimeOffset(childID, offset: cursor)
        cursor += try engine.block.getDuration(childID)
      }
    } catch {
      handleError(error)
    }
  }

  private func insertIntoMultiClipTrack(
    engine: Engine,
    clip: Clip,
    targetTrack: Track,
    engineTrackID: DesignBlockID,
    insertIndex: Int,
    timeOffset: CMTime,
    siblingOffsets: [DesignBlockID: CMTime],
  ) throws {
    try engine.block.insertChild(into: engineTrackID, child: clip.id, at: insertIndex)
    for sibling in targetTrack.clips where sibling.id != clip.id {
      let offset = siblingOffsets[sibling.id] ?? sibling.timeOffset
      try engine.block.setTimeOffset(sibling.id, offset: offset.seconds)
    }
    try engine.block.setTimeOffset(clip.id, offset: timeOffset.seconds)
  }

  private func promoteStandaloneTargetAndInsert(
    engine: Engine,
    clip: Clip,
    targetTrack: Track,
    insertIndex: Int,
    timeOffset: CMTime,
    siblingOffsets: [DesignBlockID: CMTime],
  ) throws {
    guard let pageID = timelineProperties.currentPage,
          let targetSolo = targetTrack.clips.first else { return }
    let pageChildren = try engine.block.getChildren(pageID)
    guard let pageIndex = pageChildren.firstIndex(of: targetSolo.id) else { return }

    // `appendChild` / `insertChild` move (re-parent) an existing block — so the
    // following calls move `targetSolo` from the page and `clip` from its source
    // track into the new track. No explicit `removeChild` needed.
    let newEngineTrack = try engine.block.create(DesignBlockType.track)
    try engine.block.setBool(newEngineTrack, property: "track/automaticallyManageBlockOffsets", value: false)
    try engine.block.insertChild(into: pageID, child: newEngineTrack, at: pageIndex)
    try engine.block.appendChild(to: newEngineTrack, child: targetSolo.id)
    try engine.block.insertChild(into: newEngineTrack, child: clip.id, at: insertIndex)

    let soloOffset = siblingOffsets[targetSolo.id] ?? targetSolo.timeOffset
    try engine.block.setTimeOffset(targetSolo.id, offset: soloOffset.seconds)
    try engine.block.setTimeOffset(clip.id, offset: timeOffset.seconds)
  }

  private func finalizeExistingTrackDrop(
    clip: Clip,
    targetTrack: Track,
    isCrossTrack: Bool,
    sourceWasBackground: Bool,
  ) {
    if isCrossTrack {
      cleanUpEmptyTracks()
      if sourceWasBackground, let engine {
        // Engine auto-packs the BG on insert, not on remove. `refreshTimeline`
        // packs the UI side, but without this call the engine canvas plays
        // remaining BG clips at their pre-drag offsets until an async event
        // triggers `Track::layout()`.
        packBackgroundChildren(engine: engine)
      }
    } else if targetTrack !== timelineProperties.dataSource.backgroundTrack {
      refresh(clip: clip)
      for sibling in targetTrack.clips where sibling.id != clip.id {
        refresh(clip: sibling)
      }
      return
    }
    // Cross-track or BG reorder — refreshTimeline rebuilds with reused instances and
    // recomputes the BG packed offsets deterministically.
    refreshTimeline()
    timelineProperties.suppressNextDirtyRefresh = true
  }

  /// Maps the UI's reversed-list `insertAt` to a page-children index via a same-lane
  /// anchor block, then reparents the dragged clip into a fresh engine track at that slot.
  /// The audio-sort in `refreshTimeline` inverts the pc-to-visual relationship for audio
  /// (lower pc = higher visually), so audio drags use the anchor's pc directly rather than
  /// `pc + 1`, and fall back to walking *upward* (insert after) when no anchor sits below.
  private func applyNewTrackDrop(engine: Engine, clip: Clip, insertAt: Int, timeOffset: CMTime) {
    guard let pageID = timelineProperties.currentPage else { return }
    let sourceWasBackground = timelineProperties.dataSource.findTrack(containing: clip)
      === timelineProperties.dataSource.backgroundTrack
    do {
      let pageChildren = try engine.block.getChildren(pageID)
      let tracks = timelineProperties.dataSource.tracks
      let draggedIsAudio = clip.clipType == .audio || clip.clipType == .voiceOver

      func anchorPageIndex(for track: Track) -> Int? {
        guard let anchor = track.engineTrackID ?? track.clips.first?.id else { return nil }
        return pageChildren.firstIndex(of: anchor)
      }
      func laneMatches(_ track: Track) -> Bool {
        let trackIsAudio = track.clips.first.map { $0.clipType == .audio || $0.clipType == .voiceOver } ?? false
        return trackIsAudio == draggedIsAudio
      }

      let engineInsertionIndex: Int = {
        // Walk down (toward visually lower neighbors) for a same-lane anchor.
        var probe = min(max(insertAt - 1, -1), tracks.count - 1)
        while probe >= 0 {
          let track = tracks[probe]
          if laneMatches(track), let anchorIndex = anchorPageIndex(for: track) {
            // Visual: insert AFTER the anchor (higher pc → above it visually).
            // Audio: insert AT the anchor's pc (lower pc → above it visually).
            return draggedIsAudio ? anchorIndex : anchorIndex + 1
          }
          probe -= 1
        }
        // Audio with no same-lane anchor below — look upward and insert AFTER it
        // (higher pc → below it visually under the audio sort).
        if draggedIsAudio {
          var upProbe = max(insertAt, 0)
          while upProbe < tracks.count {
            let track = tracks[upProbe]
            if laneMatches(track), let anchorIndex = anchorPageIndex(for: track) {
              return anchorIndex + 1
            }
            upProbe += 1
          }
        }
        return 0
      }()

      let newEngineTrack = try engine.block.create(DesignBlockType.track)
      try engine.block.setBool(newEngineTrack, property: "track/automaticallyManageBlockOffsets", value: false)
      try engine.block.insertChild(into: pageID, child: newEngineTrack, at: engineInsertionIndex)
      try engine.block.insertChild(into: newEngineTrack, child: clip.id, at: 0)
      try engine.block.setTimeOffset(clip.id, offset: timeOffset.seconds)

      addUndoStep()
      cleanUpEmptyTracks()
      if sourceWasBackground {
        // Engine auto-packs the BG on insert, not on remove. `refreshTimeline`
        // packs the UI side, but without this call the engine canvas plays
        // remaining BG clips at their pre-drag offsets until an async event
        // triggers `Track::layout()`.
        packBackgroundChildren(engine: engine)
      }
      refreshTimeline()
      timelineProperties.suppressNextDirtyRefresh = true
    } catch {
      handleError(error)
    }
  }

  // MARK: Trimming

  /// Called before `setTrim` on drag end so `Track::layout()` sees the right adjacent
  /// context and doesn't push the dragged clip away from the trimmed edge.
  func commitPreviewedOffsets(_ offsets: [DesignBlockID: CMTime]) {
    guard let engine else { return }
    let sortedIDs = offsets.keys.sorted()
    for blockID in sortedIDs {
      guard let offset = offsets[blockID] else { continue }
      do {
        try engine.block.setTimeOffset(blockID, offset: offset.seconds)
      } catch {
        handleError(error)
      }
    }
    for blockID in sortedIDs {
      if let clip = timelineProperties.dataSource.findClip(id: blockID) {
        refresh(clip: clip)
      }
    }
  }

  /// Sets a new trim to the passed `Clip` and its corresponding `DesignBlock`.
  /// - Parameters:
  ///   - clip: The `Clip` that will get the new trim.
  ///   - timeOffset: The offset relative to the containing `Page`.
  ///   - trimOffset: The offset in the `Clip`’s footage.
  ///   - duration: The duration for how long the `Clip` will be visible during playback.
  func setTrim(clip: Clip, timeOffset: CMTime, trimOffset: CMTime, duration: CMTime) {
    setTimeOffset(clip: clip, timeOffset: timeOffset)
    setTrimOffset(clip: clip, trimOffset: trimOffset)
    setDuration(clip: clip, duration: duration)

    // Call refresh manually to apply the change immediately (without a glitch):
    refresh(clip: clip)

    // Work around the engine's `Track::layout()` gap-handling bug by packing clips
    // ourselves on submit (like web's `packElements`).
    if !clip.isInBackgroundTrack,
       let track = timelineProperties.dataSource.findTrack(containing: clip),
       track.engineTrackID != nil {
      packAndPersistTrackClips(track: track)
    }

    // Sync now so anchored UI (e.g. "+ Add Clip") doesn't flicker before the async
    // engine event arrives. Mostly relevant for background trims.
    updateDurations()

    addUndoStep()
  }

  /// Mirrors web's `packElements`: walk the track left-to-right, resolve overlaps,
  /// persist positions, refresh.
  private func packAndPersistTrackClips(track: Track) {
    guard let engine else { return }
    let sorted = track.clips.sorted { $0.timeOffset < $1.timeOffset }
    var cursor: CMTime = .zero

    for (index, clip) in sorted.enumerated() {
      let duration = clip.duration ?? .zero

      if clip.isLocked {
        // Locked clips stay at their authored position. Re-write it explicitly so the
        // engine's `Track::layout()` (triggered by `setDuration` / `insertChild`) can't
        // leave a locked clip drifted to a position we never asked for. Advance the
        // cursor monotonically past it so trailing unlocked clips pack behind.
        do {
          try engine.block.setTimeOffset(clip.id, offset: clip.timeOffset.seconds)
        } catch {
          handleError(error)
        }
        cursor = max(cursor, clip.timeOffset + duration)
        continue
      }

      let nextLockedStart = sorted[(index + 1)...]
        .first(where: { $0.isLocked })?.timeOffset

      var resolvedOffset = max(clip.timeOffset, cursor)
      if let nextLockedStart {
        // Cap at the next locked clip so an unlocked one can't overlap it.
        let cap = nextLockedStart - duration
        if cap >= cursor {
          resolvedOffset = min(resolvedOffset, cap)
        }
        // If cap < cursor, the clip can't fit — accept overlap (the trim cap should
        // prevent reaching this state).
      }

      clip.timeOffset = resolvedOffset
      do {
        try engine.block.setTimeOffset(clip.id, offset: resolvedOffset.seconds)
      } catch {
        handleError(error)
      }
      cursor = resolvedOffset + duration
    }

    for clip in track.clips {
      refresh(clip: clip)
    }
  }

  /// Sets the time offset.
  private func setTimeOffset(clip: Clip, timeOffset: CMTime) {
    guard let engine else { return }
    do {
      try engine.block.setTimeOffset(clip.id, offset: timeOffset.seconds)
    } catch {
      handleError(error)
    }
  }

  /// Sets the trim offset.
  private func setTrimOffset(clip: Clip, trimOffset: CMTime) {
    guard let engine else { return }
    guard clip.allowsTrimming else { return }
    do {
      try engine.block.setTrimOffset(clip.trimmableID, offset: trimOffset.seconds)
    } catch {
      handleError(error)
    }
  }

  /// Sets the duration.
  private func setDuration(clip: Clip, duration: CMTime) {
    guard let engine else { return }
    do {
      try engine.block.setDuration(clip.id, duration: duration.seconds)

      if clip.clipType == .audio {
        try engine.block.setTrimLength(clip.id, length: duration.seconds)
      } else if clip.clipType == .video,
                let fillID = clip.fillID {
        try engine.block.setTrimLength(fillID, length: duration.seconds)
      }
    } catch {
      handleError(error)
    }
  }

  // MARK: Split

  /// Split the selected clip if the playhead position is currently within its bounds.
  func splitSelectedClipAtPlayheadPosition() {
    guard let engine else { return }
    guard let totalDuration = timelineProperties.timeline?.totalDuration else { return }
    let playheadPosition = timelineProperties.player.playheadPosition

    guard let clip = timelineProperties.selectedClip else { return }

    let absoluteStartTime = clip.timeOffset
    let originalClipDurationOrInfinity = clip.duration ?? CMTime.positiveInfinity

    // Pick the clip that is currently under the playhead.
    if absoluteStartTime < playheadPosition,
       absoluteStartTime + originalClipDurationOrInfinity > playheadPosition {
      deselect()

      let firstClipDuration = playheadPosition - absoluteStartTime
      let remainingTotalDurationInPage = totalDuration - playheadPosition
      // If the clip doesn’t have a duration set, we use the remaining duration of the page to check the min duration.
      let secondClipDurationOrRemainingTotalDuration = clip.duration != nil
        ? clip.duration! - firstClipDuration
        : remainingTotalDurationInPage
      guard firstClipDuration >= timelineProperties.configuration.minClipDuration,
            secondClipDurationOrRemainingTotalDuration >= timelineProperties.configuration.minClipDuration else {
        handleError(
          Error(errorDescription: String(localized: .imgly
              .localized("ly_img_editor_timeline_error_split_short_duration"))),
        )
        return
      }

      do {
        _ = try engine.block.split(
          clip.id,
          atTime: firstClipDuration.seconds,
          options: SplitOptions(createParentTrackIfNeeded: true),
        )

        addUndoStep()

        // `createParentTrackIfNeeded` re-parents both halves into a new track, which
        // snaps the playhead back to the first half's start. Restore it.
        setPlayheadPosition(playheadPosition)
      } catch {
        handleError(error)
      }
    } else {
      handleError(
        Error(errorDescription: String(localized: .imgly.localized("ly_img_editor_timeline_error_split_out_of_range"))),
      )
    }
  }

  // MARK: Reorder

  /// Moves the passed `Clip` to the new `index`.
  func reorderBackgroundTrack(clip: Clip, toIndex index: Int) {
    guard let engine,
          let backgroundTrack = timelineProperties.backgroundTrack else { return }
    do {
      try engine.block.insertChild(into: backgroundTrack, child: clip.id, at: index)

      addUndoStep()
    } catch {
      handleError(error)
    }
  }

  // MARK: Refresh

  /// Refreshes the thumbnails for all clips in the timeline.
  func refreshThumbnails() {
    for clip in timelineProperties.dataSource.allClips() {
      refreshThumbnail(clip: clip)
    }
  }

  /// Refreshes the thumbnail for a specific clip.
  /// - Parameter clip: The clip for which to refresh the thumbnail.
  func refreshThumbnail(clip: Clip) {
    guard let timeline = timelineProperties.timeline else { return }

    if let duration = clip.duration {
      let width = timeline.convertToPoints(time: duration)
      let height = clip.isInBackgroundTrack
        ? timelineProperties.configuration.backgroundTrackHeight
        : timelineProperties.configuration.trackHeight

      do {
        try timelineProperties.thumbnailsManager.refreshThumbnails(for: clip, width: width, height: height)
      } catch {
        handleError(error)
      }
    }
  }

  /// Refreshes the thumbnail for a specific clip by its ID.
  /// - Parameter id: The ID of the clip.v
  func refreshThumbnail(id: DesignBlockID) {
    if let clip = timelineProperties.dataSource.findClip(id: id) {
      refreshThumbnail(clip: clip)
    }
  }

  /// Updates a clip representation in the timeline.
  /// - Parameter clip: The clip to update.
  private func refresh(clip: Clip) {
    refresh(id: clip.id, clip: clip)
  }

  // swiftlint:disable cyclomatic_complexity
  /// Creates a new clip or updates the passed existing clip representation in the timeline.
  /// - Parameters:
  ///   - id: The engine block ID.
  ///   - existingClip: An existing clip to update, or `nil` to create a new one.
  ///   - targetTrack: When creating a new clip, the track to add it to. When `nil`, a new track is created.
  private func refresh(id: DesignBlockID, clip existingClip: Clip?, targetTrack: Track? = nil) {
    guard let engine else { return }

    // Check if the block still exists or whether it has been deleted already.
    guard engine.block.isValid(id) else { return }

    do {
      let clip = existingClip ?? Clip(id: id)

      let fillID = try engine.block.supportsFill(id) ? try engine.block.getFill(id) : nil
      clip.fillID = fillID

      let fillType = fillID != nil ? try engine.block.getType(fillID!) : nil

      if let fillID, fillType == FillType.video.rawValue {
        clip.trimmableID = fillID
      } else {
        clip.trimmableID = id
      }

      clip.allowsSelecting = try engine.block.isAllowedByScope(id, scope: .init(.editorSelect))

      clip.shapeID = try engine.block.supportsShape(id) ? try engine.block.getShape(id) : nil
      clip.effectIDs = try engine.block.supportsEffects(id) ? try engine.block.getEffects(id) : []
      clip.blurID = try engine.block.supportsBlur(id) ? try engine.block.getBlur(id) : nil

      // Configure clip type
      let blockType = try engine.block.getType(id)
      let blockKind: BlockKind? = try? engine.block.getKind(id)

      switch blockType {
      case DesignBlockType.audio.rawValue:
        try configureAudioClip(clip, id: id, kind: blockKind)
      case DesignBlockType.graphic.rawValue:
        // Important: Don’t throw here!
        try configureGraphicClip(clip, fillType: fillType, kind: blockKind, fillID: fillID)
      case DesignBlockType.text.rawValue:
        clip.clipType = .text
        clip.configuration = timelineProperties.configuration.textClipConfiguration
      case DesignBlockType.group.rawValue:
        clip.clipType = .group
        clip.configuration = timelineProperties.configuration.groupClipConfiguration
      case DesignBlockType.page.rawValue:
        // The page block should not appear in the timeline.
        return
      default:
        // Not every block in the engine has a timeline representation, so we just ignore other block types.
        return
      }

      // Check if clip should be in the backgroundTrack
      if let backgroundTrack = timelineProperties.backgroundTrack {
        clip.isInBackgroundTrack = (try? engine.block.getChildren(backgroundTrack).contains(id)) ?? false
      }

      try setClipTimingProperties(clip)
      try setClipPlaybackSpeedProperties(clip)
      try setClipTrimOffsetProperties(clip)

      try setClipAVResourceProperties(clip)
      try setClipAudioProperties(clip)

      // If this is a freshly created clip, we need to add it to the timeline
      if existingClip == nil {
        let track: Track = if clip.isInBackgroundTrack {
          timelineProperties.dataSource.backgroundTrack
        } else if let targetTrack {
          // Clip belongs to a multi-clip engine track — use the provided track.
          targetTrack
        } else {
          // Standalone foreground clip — create a new UI track.
          Track()
        }

        track.clips.append(clip)
        if !clip.isInBackgroundTrack, targetTrack == nil {
          // Only append to dataSource when we created a new track.
          // Tracks provided via targetTrack are already appended by refreshTimeline().
          timelineProperties.dataSource.tracks.append(track)
        }
      }

      timelineProperties.dataSource.updateSnapDetents()
    } catch {
      handleError(error)
    }
  }

  // MARK: Clip's Configure

  private func configureGraphicClip(_ clip: Clip, fillType: String?, kind: BlockKind?, fillID: DesignBlockID?) throws {
    switch fillType {
    case FillType.image.rawValue:
      try configureImageClip(clip, kind: kind, fillID: fillID)
    case FillType.video.rawValue:
      try configureVideoClip(clip, kind: kind, fillID: fillID)
    default:
      clip.clipType = .shape
      clip.configuration = timelineProperties.configuration.shapeClipConfiguration
      clip.title = ""
    }
  }

  private func configureImageClip(_ clip: Clip, kind: BlockKind?, fillID: DesignBlockID?) throws {
    guard let fillID else { throw Error(errorDescription: "Image has no fill") }

    switch kind {
    case .key(.sticker):
      clip.clipType = .sticker
      clip.configuration = timelineProperties.configuration.stickerClipConfiguration
    default:
      clip.clipType = .image
      clip.configuration = timelineProperties.configuration.imageClipConfiguration
    }
    clip.title = ""
    clip.footageURLString = try engine?.block.get(fillID, property: .key(.fillImageImageFileURI))
  }

  private func configureVideoClip(_ clip: Clip, kind: BlockKind?, fillID: DesignBlockID?) throws {
    guard let fillID else { throw Error(errorDescription: "Video block has no fill") }

    switch kind {
    case .key(.animatedSticker):
      clip.configuration = timelineProperties.configuration.stickerClipConfiguration
    default:
      clip.configuration = timelineProperties.configuration.videoClipConfiguration
    }
    clip.clipType = .video
    clip.title = ""
    clip.footageURLString = try engine?.block.get(fillID, property: .key(.fillVideoFileURI))
  }

  private func configureAudioClip(_ clip: Clip, id: DesignBlockID, kind: BlockKind?) throws {
    switch kind {
    case .key(.voiceover):
      clip.clipType = .voiceOver
      clip.configuration = timelineProperties.configuration.voiceOverClipConfiguration
    default:
      clip.clipType = .audio
      clip.configuration = timelineProperties.configuration.audioClipConfiguration
    }
    if let name = try? engine?.block.getMetadata(id, key: "name"), !name.isEmpty {
      clip.title = name
    } else {
      clip.title = ""
    }
    clip.footageURLString = try engine?.block.get(id, property: .key(.audioFileURI))
  }

  // MARK: Clip's Set Properties

  private func setClipTimingProperties(_ clip: Clip) throws {
    guard let engine else { return }

    let durationSeconds = try engine.block.getDuration(clip.id)
    if durationSeconds > Double(Int.max) {
      clip.duration = nil
    } else {
      clip.duration = CMTime(seconds: durationSeconds)
    }

    let timeOffsetSeconds = try engine.block.getTimeOffset(clip.id)
    clip.timeOffset = CMTime(seconds: timeOffsetSeconds)

    if let fill = clip.fillID,
       let type = try? engine.block.getType(fill),
       type == FillType.video.rawValue {
      let isLooping = try engine.block.isLooping(fill)
      clip.isLooping = isLooping
    }

    if (try? engine.block.supportsAnimation(clip.id)) == true {
      let hasInAnimation = (try? engine.block.getInAnimation(clip.id)).map { engine.block.isValid($0) } ?? false
      let hasLoopAnimation = (try? engine.block.getLoopAnimation(clip.id)).map { engine.block.isValid($0) } ?? false
      let hasOutAnimation = (try? engine.block.getOutAnimation(clip.id)).map { engine.block.isValid($0) } ?? false
      clip.hasAnimation = hasInAnimation || hasLoopAnimation || hasOutAnimation
    }
  }

  private func setClipPlaybackSpeedProperties(_ clip: Clip) throws {
    guard let engine else { return }

    if try engine.block.supportsPlaybackControl(clip.trimmableID) {
      clip.playbackSpeed = try engine.block.getPlaybackSpeed(clip.trimmableID)
    } else if try engine.block.supportsPlaybackControl(clip.id) {
      clip.playbackSpeed = try engine.block.getPlaybackSpeed(clip.id)
    } else {
      clip.playbackSpeed = 1
    }
  }

  private func setClipTrimOffsetProperties(_ clip: Clip) throws {
    guard let engine else { return }

    let isLiveBufferAudio = (clip.clipType == .audio || clip.clipType == .voiceOver) &&
      (clip.footageURLString?.hasPrefix("buffer://") == true)
    if isLiveBufferAudio {
      clip.allowsTrimming = false
      clip.trimOffset = .zero
      return
    }

    clip.allowsTrimming = try engine.block.supportsTrim(clip.trimmableID)
    if clip.allowsTrimming {
      // Create the clip even if the trimOffset is not available yet
      // Important: Don't throw here; we want to create the clip even if we don't know if it has a trim.
      let trimOffsetSeconds = (try? engine.block.getTrimOffset(clip.trimmableID)) ?? 0
      clip.trimOffset = CMTime(seconds: trimOffsetSeconds)
    }
  }

  private func setClipAVResourceProperties(_ clip: Clip) throws {
    guard let engine else { return }

    guard clip.clipType == .audio || clip.clipType == .video || clip.clipType == .voiceOver else {
      clip.footageDuration = nil
      return
    }

    let isLiveBufferAudio = (clip.clipType == .audio || clip.clipType == .voiceOver) &&
      (clip.footageURLString?.hasPrefix("buffer://") == true)
    if isLiveBufferAudio {
      clip.footageDuration = clip.duration
      clip.isLoading = false
      clip.allowsTrimming = false
      return
    }

    clip.isLoading = !(try engine.block.unstable_isAVResourceLoaded(clip.trimmableID))

    if let footageDurationSeconds = try? engine.block.getAVResourceTotalDuration(clip.trimmableID) {
      clip.footageDuration = CMTime(seconds: footageDurationSeconds)
      clip.allowsTrimming = true
    } else {
      clip.footageDuration = clip.duration
      clip.allowsTrimming = false
      clip.isLoading = true

      blockTasks[clip.trimmableID]?.cancel()
      let task = Task {
        do {
          try await engine.block.forceLoadAVResource(clip.trimmableID)
          clip.isLoading = false
        } catch {
          // Handle error appropriately
        }
        self.blockTasks[clip.trimmableID] = nil
      }
      blockTasks[clip.trimmableID] = task
    }
  }

  private func setClipAudioProperties(_ clip: Clip) throws {
    guard let engine else { return }

    guard clip.clipType == .audio || clip.clipType == .video || clip.clipType == .voiceOver else {
      clip.isMuted = false
      clip.audioVolume = 1.0
      return
    }

    clip.isMuted = try engine.block.isMuted(clip.trimmableID)
    clip.audioVolume = Double(try engine.block.getVolume(clip.trimmableID))
  }

  // swiftlint:enable cyclomatic_complexity

  /// Rebuilds the timeline from the engine, reusing existing `Track`/`Clip`
  /// instances so SwiftUI keeps view identity across refreshes.
  func refreshTimeline() {
    guard let engine, let pageID = timelineProperties.currentPage else { return }
    do {
      let blocks = try audioFirstOrderedPageChildren(engine: engine, pageID: pageID)
      let backgroundChildren = try resolveBackgroundTrack(engine: engine)
      let cache = buildOldClipCache()

      func resolveClip(_ id: DesignBlockID) -> Clip? {
        guard engine.block.isValid(id) else { return nil }
        let clip = cache.clipByID[id] ?? Clip(id: id)
        refresh(id: id, clip: clip)
        return clip
      }

      let newTracks = try blocks
        .filter { $0 != timelineProperties.backgroundTrack }
        .compactMap { try buildTrack(forBlock: $0, engine: engine, cache: cache, resolveClip: resolveClip) }
      let newBgClips = packBackground(backgroundChildren.compactMap(resolveClip))

      timelineProperties.dataSource.tracks = newTracks
      timelineProperties.dataSource.backgroundTrack.clips = newBgClips
      timelineProperties.dataSource.updateSnapDetents()
      updateTimelineSelectionFromCanvas()
    } catch {
      handleError(error)
    }
  }

  /// Page children with audio-like blocks moved to the front (matches engine ordering).
  private func audioFirstOrderedPageChildren(engine: Engine, pageID: DesignBlockID) throws -> [DesignBlockID] {
    var blocks = try engine.block.getChildren(pageID)
    blocks.removeAll { $0 == timelineProperties.scrubbingPreviewLayer }
    var audioBlocks = [DesignBlockID]()
    for (i, block) in blocks.enumerated().reversed() where (try? engine.block.isAudioLike(block)) == true {
      blocks.remove(at: i)
      audioBlocks.append(block)
    }
    blocks.insert(contentsOf: audioBlocks, at: 0)
    return blocks
  }

  /// Resolves the page-duration-source background track and returns its current children.
  /// Side-effects: updates `timelineProperties.backgroundTrack` and the data-source mirror.
  private func resolveBackgroundTrack(engine: Engine) throws -> [DesignBlockID] {
    timelineProperties.backgroundTrack = try engine.block.find(byType: .track)
      .first { try engine.block.isPageDurationSource($0) }
    if let bgTrack = timelineProperties.backgroundTrack, engine.block.isValid(bgTrack) {
      timelineProperties.dataSource.backgroundTrack.engineTrackID = bgTrack
      return try engine.block.getChildren(bgTrack)
    }
    timelineProperties.backgroundTrack = nil
    timelineProperties.dataSource.backgroundTrack.engineTrackID = nil
    return []
  }

  private struct OldTrackCache {
    var trackByEngineID: [DesignBlockID: Track] = [:]
    var standaloneByClipID: [DesignBlockID: Track] = [:]
    var clipByID: [DesignBlockID: Clip] = [:]
  }

  /// Indexes existing tracks/clips so the next refresh can reuse the same instances.
  private func buildOldClipCache() -> OldTrackCache {
    var cache = OldTrackCache()
    for track in timelineProperties.dataSource.tracks {
      if let engineID = track.engineTrackID {
        cache.trackByEngineID[engineID] = track
      } else if let clipID = track.clips.first?.id {
        cache.standaloneByClipID[clipID] = track
      }
      for clip in track.clips {
        cache.clipByID[clip.id] = clip
      }
    }
    for clip in timelineProperties.dataSource.backgroundTrack.clips {
      cache.clipByID[clip.id] = clip
    }
    return cache
  }

  private func buildTrack(
    forBlock block: DesignBlockID,
    engine: Engine,
    cache: OldTrackCache,
    resolveClip: (DesignBlockID) -> Clip?,
  ) throws -> Track? {
    let blockType = try engine.block.getType(block)
    if blockType == DesignBlockType.track.rawValue {
      let track = cache.trackByEngineID[block] ?? Track(engineTrackID: block)
      track.clips = try engine.block.getChildren(block).compactMap(resolveClip)
      return track
    }
    guard let clip = resolveClip(block) else { return nil }
    let track = cache.standaloneByClipID[block] ?? Track()
    track.clips = [clip]
    return track
  }

  /// BG auto-packs lazily — pack offsets ourselves to keep cells stable through the post-drop tick.
  private func packBackground(_ clips: [Clip]) -> [Clip] {
    var packedCursor = CMTime.zero
    for clip in clips {
      if clip.timeOffset != packedCursor {
        clip.timeOffset = packedCursor
      }
      // swiftlint:disable:next shorthand_operator
      packedCursor = packedCursor + (clip.duration ?? .zero)
    }
    return clips
  }

  /// Updates the total duration of the page by reading it from the engine.
  private func updateDurations() {
    guard let engine,
          let timeline = timelineProperties.timeline,
          let pageID = timelineProperties.currentPage else { return }

    do {
      let pageDuration = try engine.block.getDuration(pageID)
      let clipsDuration = timelineProperties.dataSource.allClips()
        .map { clip in
          let clipDuration = clip.duration?.seconds ?? max(0, pageDuration - clip.timeOffset.seconds)
          return clip.timeOffset.seconds + max(0, clipDuration)
        }
        .max() ?? 0
      // Sum local BG clip durations rather than reading `engine.block.getDuration(pageID)`.
      // Right after a BG trim commit, `refresh(clip:)` has already pushed the new
      // duration into the local `Clip`, but the engine's page duration can lag a frame
      // — reading it here would briefly snap the "+ Add Clip" anchor back to the
      // pre-trim position before the engine event lands.
      let resolvedDuration: Double = if timelineProperties.backgroundTrack != nil {
        timelineProperties.dataSource.backgroundTrack.clips
          .reduce(0.0) { $0 + ($1.duration?.seconds ?? 0) }
      } else {
        max(pageDuration, clipsDuration)
      }
      let totalDuration = CMTime(seconds: resolvedDuration)

      if totalDuration != CMTime(seconds: timeline.totalDuration.seconds) {
        timelineProperties.timeline?.setTotalDuration(totalDuration)
      }
    } catch {
      handleError(error)
    }
  }

  // MARK: Scrubbing

  /// Adds the temporary extra block that is used as a preview layer.
  private func addScrubbingPreviewLayer() {
    guard let engine,
          let totalDuration = timelineProperties.timeline?.totalDuration,
          let pageID = timelineProperties.currentPage else { return }

    do {
      timelineProperties.isScrubbing = true
      let scrubbingPreviewLayer = try engine.block.create(DesignBlockType.graphic)
      let shape = try engine.block.createShape(.rect)
      try engine.block.setShape(scrubbingPreviewLayer, shape: shape)

      timelineProperties.scrubbingPreviewLayer = scrubbingPreviewLayer
      try engine.block.appendChild(to: pageID, child: scrubbingPreviewLayer)
      try engine.block.fillParent(scrubbingPreviewLayer)
      try engine.block.setVisible(scrubbingPreviewLayer, visible: false)

      try engine.block.setAlwaysOnTop(scrubbingPreviewLayer, enabled: true)
      try engine.block.setDuration(scrubbingPreviewLayer, duration: totalDuration.seconds)
    } catch {
      handleError(error)
    }
  }

  /// Starts solo playback for the clip when starting to move the trim handles.
  func startScrubbing(clip: Clip) {
    guard let engine else { return }

    timelineProperties.isScrubbing = true
    guard clip.clipType == .video, clip.allowsTrimming else { return }
    guard let footageDuration = clip.effectiveFootageDuration else { return }

    addScrubbingPreviewLayer()
    guard let scrubbingPreviewLayer = timelineProperties.scrubbingPreviewLayer else { return }

    do {
      try engine.block.setVisible(scrubbingPreviewLayer, visible: true)

      // We copy the fill and reset its trimOffset and trimLength.
      // Then we apply it to an extra previewing block that is dynamically shown and hidden.
      let fillID = clip.trimmableID
      try engine.block.setFill(scrubbingPreviewLayer, fill: fillID)
      try engine.block.setTrimOffset(fillID, offset: 0)
      try engine.block.setTrimLength(fillID, length: footageDuration.seconds)
      try engine.block.setSoloPlaybackEnabled(fillID, enabled: true)
    } catch {
      handleError(error)
    }
  }

  /// Seeks a time in solo playback while moving the trim handles.
  func scrub(clip: Clip, time: CMTime) {
    guard let engine else { return }
    guard let scrubbingPreviewLayer = timelineProperties.scrubbingPreviewLayer else { return }

    guard let footageDuration = clip.effectiveFootageDuration else { return }
    let clampedTime = time.clamped(to: CMTime(seconds: 0) ... footageDuration)
    guard clip.clipType == .video else { return }

    do {
      let fillID = try engine.block.getFill(scrubbingPreviewLayer)
      try engine.block.setPlaybackTime(fillID, time: clampedTime.seconds)
    } catch {
      handleError(error)
    }
  }

  /// Stops solo playback for the clip when finishing to move the trim handles. Deletes the temporary preview block.
  func stopScrubbing(clip: Clip) {
    defer {
      timelineProperties.isScrubbing = false
    }
    guard let engine else { return }
    guard let scrubbingPreviewLayer = timelineProperties.scrubbingPreviewLayer else { return }
    guard clip.clipType == .video else { return }

    do {
      let fillID = try engine.block.getFill(scrubbingPreviewLayer)
      try engine.block.setSoloPlaybackEnabled(fillID, enabled: false)

      // Destroying the block triggers a late .destroyed event that would cause
      // a refresh, so we don’t set the interactor’s corresponding property to nil yet.
      // This lets us filter the event in our subscription and prevenet a timeline refresh.
      try engine.block.destroy(scrubbingPreviewLayer)
    } catch {
      handleError(error)
    }
  }

  // MARK: Selection

  /// Select a clip immediately both in the timeline and on canvas (if applicable).
  func select(id: DesignBlockID?) {
    guard let id else {
      // Passing `nil` deselects.
      deselect()
      return
    }

    // Prevent an infinite loop with the engine selection updates while still allowing
    // canvas selection to be restored for clips that are not in the local timeline cache yet.
    let clip = timelineProperties.dataSource.findClip(id: id)
    if timelineProperties.selectedClip?.id == id, clip != nil {
      return
    }

    if let clip {
      timelineProperties.selectedClip = clip
    }

    guard engine?.block.isValid(id) == true else { return }
    selectOnCanvas(id: id)
    pause()
  }

  /// Deselect a clip immediately both in the timeline and on canvas.
  func deselect() {
    deselectOnCanvas()
    timelineProperties.selectedClip = nil
  }

  // MARK: Deletion

  func delete(id: DesignBlockID?) {
    guard let id, let engine else {
      return
    }

    do {
      try engine.block.destroy(id)
    } catch {
      handleError(error)
    }
  }

  // MARK: Audio

  func setPageMuted(_ muted: Bool) {
    guard let engine, let pageID = timelineProperties.currentPage else { return }
    do {
      try engine.block.setMuted(pageID, muted: muted)
    } catch {
      handleError(error)
    }
  }

  func setBlockMuted(_ id: DesignBlockID?, muted: Bool) {
    guard let engine, let id else { return }
    do {
      try engine.block.setMuted(id, muted: muted)
    } catch {
      handleError(error)
    }
  }

  // MARK: Update and sync the selection state

  /// Sync the timeline’s selected clip to match what’s currently selected on the canvas.
  /// This only updates the timeline state without modifying the canvas selection or edit mode,
  /// which would otherwise cause sheets (e.g. crop) to close due to re-entrant selection events.
  func updateTimelineSelectionFromCanvas() {
    guard timelineProperties.timeline != nil else { return }
    guard let engine else { return }
    let selected = engine.block.findAllSelected()
    guard let id = selected.first else {
      timelineProperties.selectedClip = nil
      return
    }

    if isVoiceOverRecordModeActive,
       voiceOverRecordModeSelectionHidden,
       let target = voiceOverRecordModeTarget,
       id == target {
      timelineProperties.selectedClip = nil
      return
    }

    // Allow selecting the page and do nothing in the timeline
    guard id != timelineProperties.currentPage else {
      timelineProperties.selectedClip = nil
      return
    }

    let clip = timelineProperties.dataSource.findClip(id: id)
    guard timelineProperties.selectedClip?.id != id || clip == nil else { return }
    timelineProperties.selectedClip = clip
    if clip != nil {
      pause()
    }
  }

  /// Select a block on the canvas.
  private func selectOnCanvas(id: DesignBlockID) {
    guard let engine else { return }
    do {
      try engine.block.select(id)
    } catch {
      handleError(error)
    }
  }

  /// Deselect a block on the canvas.
  private func deselectOnCanvas() {
    guard let engine else { return }
    let selectedIDs = engine.block.findAllSelected()
    for selectedID in selectedIDs {
      do {
        try engine.block.setSelected(selectedID, selected: false)
      } catch {
        handleError(error)
      }
    }
  }

  // MARK: Thumbnails

  /// Retrieve the aspect ratio of a block.
  func getAspectRatio(clip: Clip) throws -> Double {
    guard let engine else { throw Error(errorDescription: "Missing engine") }

    let aspectRatio: Double
    if clip.clipType != .audio {
      let width = try engine.block.getFrameWidth(clip.id)
      let height = try engine.block.getFrameHeight(clip.id)
      if width > 0, height > 0 {
        aspectRatio = Double(width) / Double(height)
      } else {
        aspectRatio = 1
      }
    } else {
      aspectRatio = 1
    }
    return aspectRatio
  }

  func getTextContent(id: DesignBlockID) throws -> String {
    guard let engine else { throw Error(errorDescription: "Missing engine") }

    return try engine.block.getString(id, property: "text/text")
  }

  /// Generate thumbnails from a clip.
  /// - Parameters:
  ///   - clip: The `Clip` to generate the thumbnails for.
  ///   - thumbHeight: The height of the thumbnails in points.
  ///   - timeRange: The time range in the clip’s footage to generate from.
  ///   - screenResolutionScaleFactor: The screen resolution scale to multiply the `thumbHeight` by. Typically `2` on an
  /// iPad and `3` on an iPhone.
  ///   - numberOfFrames: The desired frame count.
  /// - Returns: An async stream of images that finishes when all images have been loaded.
  func generateImagesThumbnails(
    clip: Clip,
    thumbHeight: CGFloat,
    timeRange: ClosedRange<Double>,
    screenResolutionScaleFactor: CGFloat,
    numberOfFrames: Int,
  ) async throws -> AsyncThrowingStream<VideoThumbnail, Swift.Error> {
    guard let engine else { throw Error(errorDescription: "Missing engine") }
    guard engine.block.isValid(clip.id) else { throw Error(errorDescription: "Block doesn’t exist") }

    return engine.block.generateVideoThumbnailSequence(
      clip.id,
      thumbnailHeight: Int(thumbHeight * screenResolutionScaleFactor),
      timeRange: timeRange,
      numberOfFrames: numberOfFrames,
    )
  }

  func generateAudioThumbnails(
    clip: Clip,
    timeRange: ClosedRange<Double>,
    numberOfSamples: Int,
  ) async throws -> AsyncThrowingStream<AudioThumbnail, Swift.Error> {
    guard let engine else { throw Error(errorDescription: "Missing engine") }
    guard engine.block.isValid(clip.id) else { throw Error(errorDescription: "Block doesn’t exist") }

    return engine.block.generateAudioThumbnailSequence(clip.id,
                                                       samplesPerChunk: numberOfSamples,
                                                       timeRange: timeRange,
                                                       numberOfSamples: numberOfSamples,
                                                       numberOfChannels: 1)
  }

  func forceLoadAudioResource(for clip: Clip) async throws {
    guard let engine else { throw Error(errorDescription: "Missing engine") }
    guard engine.block.isValid(clip.trimmableID) else { throw Error(errorDescription: "Block doesn’t exist") }
    try await engine.block.forceLoadAVResource(clip.trimmableID)
  }

  // MARK: Playback Control

  /// Start playback.
  func play(seekToStartIfNeeded: Bool) {
    guard let engine,
          let pageID = timelineProperties.currentPage else { return }
    do {
      if seekToStartIfNeeded {
        let playbackTime = try engine.block.getPlaybackTime(pageID)
        let pageDuration = try engine.block.getDuration(pageID)
        let maxDuration = timelineProperties.player.maxPlaybackDuration?.seconds ?? pageDuration

        guard maxDuration > 0 else { return }

        if CMTime(seconds: playbackTime) >= CMTime(seconds: maxDuration) {
          setPlayheadPosition(CMTime(seconds: 0))
        }
      }

      try engine.block.setPlaying(pageID, enabled: true)
    } catch {
      handleError(error)
    }
  }

  /// Pause only when actually playing. Unlike ``pause()``, avoids the idle `setPlaying` that would
  /// flip edit mode to TRANSFORM and tear down a text-edit session.
  func pauseIfNeeded() {
    if timelineProperties.player.isPlaying {
      pause()
    }
  }

  /// Pause playback.
  func pause() {
    guard let engine,
          let pageID = timelineProperties.currentPage else { return }
    do {
      try engine.block.setPlaying(pageID, enabled: false)
    } catch {
      handleError(error)
    }
  }

  /// Toggle playback.
  func togglePlayback() {
    guard let engine,
          let pageID = timelineProperties.currentPage else { return }
    let pageDuration = (try? engine.block.getDuration(pageID)) ?? 0
    let maxDuration = timelineProperties.player.maxPlaybackDuration?.seconds ?? pageDuration
    guard maxDuration > 0 else { return }
    if timelineProperties.player.isPlaying {
      pause()
    } else {
      play()
    }
  }

  /// Sets the current playback position.
  func setPlayheadPosition(_ time: CMTime) {
    guard let engine,
          let timeline = timelineProperties.timeline,
          let pageID = timelineProperties.currentPage else { return }
    do {
      let maxTimelineSeconds = timeline.totalDuration.seconds
      var clampedSeconds = min(time.seconds, maxTimelineSeconds)
      if let maxPlaybackSeconds = timelineProperties.player.maxPlaybackDuration?.seconds {
        clampedSeconds = min(clampedSeconds, maxPlaybackSeconds)
      }
      try engine.block.setPlaybackTime(pageID, time: clampedSeconds)
    } catch {
      handleError(error)
    }
  }

  private func setPlayheadPositionToEnding() {
    guard let engine,
          let totalDuration = timelineProperties.timeline?.totalDuration,
          let pageID = timelineProperties.currentPage else { return }
    do {
      let maxDuration = timelineProperties.player.maxPlaybackDuration ?? totalDuration
      try engine.block.setPlaybackTime(pageID, time: maxDuration.seconds)
    } catch {
      handleError(error)
    }
  }

  func clampPlayheadPositionToSelectedClip() {
    guard let engine,
          let pageID = timelineProperties.currentPage,
          let totalDuration = timelineProperties.timeline?.totalDuration,
          let clip = timelineProperties.selectedClip else { return }
    do {
      let currentPlaybackPosition = timelineProperties.player.playheadPosition
      let clipIn = clip.timeOffset
      var clipOut: CMTime = if let duration = clip.duration {
        clipIn + duration
      } else {
        totalDuration
      }
      // Go back a tiny bit so that we’re at the end of this clip and not at the beginning of the next.
      clipOut = CMTime(value: clipOut.value - 1)

      let clampedTime: CMTime
      if currentPlaybackPosition < clipIn {
        clampedTime = clipIn
      } else if currentPlaybackPosition > clipOut {
        clampedTime = clipOut
      } else {
        return
      }

      let maxDuration = timelineProperties.player.maxPlaybackDuration
      let resolvedTime = if let maxDuration, clampedTime > maxDuration {
        maxDuration
      } else {
        clampedTime
      }
      try engine.block.setPlaybackTime(pageID, time: resolvedTime.seconds)
    } catch {
      handleError(error)
    }
  }

  func toggleIsLoopingPlaybackEnabled() {
    guard let engine,
          let pageID = timelineProperties.currentPage else { return }
    do {
      try engine.block.setLooping(pageID, looping: !isLoopingPlaybackEnabled)
    } catch {
      handleError(error)
    }
  }

  // MARK: - Adding Assets

  func addAssetToBackgroundTrack() {
    do {
      try engine?.block.deselectAll()
      let content = SheetContent.clip
      sheet = .init(.libraryAdd {
        AssetLibrarySheet(content: content)
      }, content)
    } catch {
      handleError(error)
    }
  }

  func addAudioAsset() {
    pause()
    Task {
      do {
        try engine?.block.deselectAll()
        // Ensure that the deselect event comes before opening the sheet, otherwise the sheet closes immediately.
        try await Task.sleep(for: .milliseconds(100))
        let content = SheetContent.audio
        sheet = .init(.libraryReplace(style: .only(detent: .imgly.medium), content: {
          AssetLibrarySheet(content: content)
        }), content)
      } catch {
        handleError(error)
      }
    }
  }

  func openVoiceOver(style: SheetStyle) {
    Task { [weak self] in
      await self?.presentVoiceOverRecordMode(style: style, entry: .create)
    }
  }

  func openCamera(_ assetSourceIDs: [MediaType: String]) {
    pause()
    uploadAssetSourceIDs = assetSourceIDs
    isCameraSheetShown = true
  }

  func addCameraRecordings(_ recordings: [Recording]) {
    setPlayheadPositionToEnding()

    guard let totalDuration = timelineProperties.timeline?.totalDuration else { return }
    Task {
      do {
        var currentTimeOffset = totalDuration
        var trackForVideoIndex: [Int: DesignBlockID] = [:]
        for recording in recordings {
          for (index, video) in recording.videos.enumerated() {
            // Add to asset library without invoking assetTapped()
            isAddingCameraRecording = true
            defer {
              isAddingCameraRecording = false
            }
            let asset = try await uploadVideo(to: videoUploadAssetSourceID) { video.url }

            guard let assetURL = asset.url else { continue }
            guard let parentTrack = parentTrackForCameraVideo(
              at: index,
              memo: &trackForVideoIndex,
            ) else { continue }
            await addCameraVideo(
              fileURL: assetURL,
              rect: video.rect,
              duration: recording.duration,
              timeOffset: currentTimeOffset,
              parentTrack: parentTrack,
            )
          }
          // swiftlint:disable:next shorthand_operator
          currentTimeOffset = currentTimeOffset + recording.duration
        }
        addUndoStep()
      } catch {
        handleError(error)
      }
    }
  }

  func addCameraCapturesToTimeline(_ captures: [Capture]) {
    setPlayheadPositionToEnding()
    guard let totalDuration = timelineProperties.timeline?.totalDuration else { return }
    Task {
      isAddingCameraRecording = true
      defer { isAddingCameraRecording = false }
      do {
        var currentTimeOffset = totalDuration
        var trackForVideoIndex: [Int: DesignBlockID] = [:]
        for capture in captures {
          let captureDuration: CMTime
          switch capture {
          case let .photo(photo):
            captureDuration = photo.duration
            try await addCameraPhotoCapture(
              photo,
              timeOffset: currentTimeOffset,
              trackForVideoIndex: &trackForVideoIndex,
            )
          case let .video(recording):
            captureDuration = recording.duration
            try await addCameraVideoCapture(
              recording,
              timeOffset: currentTimeOffset,
              trackForVideoIndex: &trackForVideoIndex,
            )
          }
          // swiftlint:disable:next shorthand_operator
          currentTimeOffset = currentTimeOffset + captureDuration
        }
        addUndoStep()
      } catch {
        handleError(error)
      }
    }
  }

  private func addCameraPhotoCapture(
    _ photo: Photo,
    timeOffset: CMTime,
    trackForVideoIndex: inout [Int: DesignBlockID],
  ) async throws {
    for (index, image) in photo.images.enumerated() {
      let asset = try await uploadImage(to: imageUploadAssetSourceID) { image.url }
      guard let assetURL = asset.url else { continue }
      guard let parentTrack = parentTrackForCameraVideo(
        at: index,
        memo: &trackForVideoIndex,
      ) else { continue }
      await addCameraPhoto(
        fileURL: assetURL,
        rect: photo.images.count > 1 ? image.rect : nil,
        duration: photo.duration,
        timeOffset: timeOffset,
        parentTrack: parentTrack,
      )
    }
  }

  private func addCameraVideoCapture(
    _ recording: Recording,
    timeOffset: CMTime,
    trackForVideoIndex: inout [Int: DesignBlockID],
  ) async throws {
    for (index, video) in recording.videos.enumerated() {
      let asset = try await uploadVideo(to: videoUploadAssetSourceID) { video.url }
      guard let assetURL = asset.url else { continue }
      guard let parentTrack = parentTrackForCameraVideo(
        at: index,
        memo: &trackForVideoIndex,
      ) else { continue }
      await addCameraVideo(
        fileURL: assetURL,
        rect: video.rect,
        duration: recording.duration,
        timeOffset: timeOffset,
        parentTrack: parentTrack,
      )
    }
  }

  private func addCameraPhoto(
    fileURL: URL,
    rect: CGRect?,
    duration: CMTime,
    timeOffset: CMTime,
    parentTrack: DesignBlockID,
  ) async {
    guard let engine else { return }
    do {
      let frame = rect ?? CGRect(origin: .zero, size: CameraConfiguration.defaultVideoSize)
      guard let id = try placeImageGraphic(at: frame, fillURL: fileURL, parent: parentTrack) else { return }
      try engine.block.setDuration(id, duration: duration.seconds)
      try engine.block.setTimeOffset(id, offset: timeOffset.seconds)
    } catch {
      handleError(error)
    }
  }

  private func parentTrackForCameraVideo(
    at index: Int,
    memo: inout [Int: DesignBlockID],
  ) -> DesignBlockID? {
    if index == 0 {
      createBackgroundTrackIfNeeded()
      return timelineProperties.backgroundTrack
    }
    if let existing = memo[index] {
      return existing
    }
    guard let engine, let pageID = timelineProperties.currentPage else { return nil }
    do {
      let newTrack = try engine.block.create(.track)
      try engine.block.setBool(newTrack, property: "track/automaticallyManageBlockOffsets", value: false)
      try engine.block.appendChild(to: pageID, child: newTrack)
      memo[index] = newTrack
      return newTrack
    } catch {
      handleError(error)
      return nil
    }
  }

  private func addCameraVideo(
    fileURL: URL,
    rect: CGRect,
    duration: CMTime,
    timeOffset: CMTime,
    parentTrack: DesignBlockID,
  ) async {
    guard let engine else { return }
    do {
      let id = try engine.block.create(.graphic)
      let rectShape = try engine.block.createShape(.rect)
      try engine.block.setShape(id, shape: rectShape)

      try engine.block.appendChild(to: parentTrack, child: id)
      try engine.block.setWidth(id, value: Float(rect.width))
      try engine.block.setHeight(id, value: Float(rect.height))
      try engine.block.setPositionX(id, value: Float(rect.origin.x))
      try engine.block.setPositionY(id, value: Float(rect.origin.y))

      try engine.block.setDuration(id, duration: duration.seconds)
      try engine.block.setTimeOffset(id, offset: timeOffset.seconds)
      let fill = try engine.block.createFill(.video)
      try engine.block.set(fill, property: .key(.fillVideoFileURI), value: fileURL)
      try engine.block.setFill(id, fill: fill)
      try await engine.block.forceLoadAVResource(fill)
    } catch {
      handleError(error)
    }
  }

  func openSystemCamera(_ assetSourceIDs: [MediaType: String], addToBackgroundTrack: Bool = false) {
    pause()
    uploadAssetSourceIDs = assetSourceIDs
    isSystemCameraShown = true
    sheet.content = addToBackgroundTrack ? .clip : .image
  }

  func addAssetsFromImagePicker(_ assets: [(URL, MediaType)]) {
    Task {
      for (index, (url, mediaType)) in assets.enumerated() {
        if index == assets.count - 1 {
          // This ensures the playhead is set to the last clip correctly.
          // Going foward we should maybe move this operation to the upload
          try await Task.sleep(for: .milliseconds(100))
        }

        _ = switch mediaType {
        case .image:
          try await uploadImage(to: imageUploadAssetSourceID) { url }
        case .movie:
          try await uploadVideo(to: videoUploadAssetSourceID) { url }
        }
      }
    }
  }

  // MARK: - Background Track Management

  /// Moves the currently selected `Clip` in or out of the background track.
  func toggleSelectedClipIsInBackgroundTrack() {
    createBackgroundTrackIfNeeded()
    guard let engine,
          let pageID = timelineProperties.currentPage,
          let backgroundTrack = timelineProperties.backgroundTrack,
          let backgroundTrackBlocks = try? engine.block.getChildren(backgroundTrack) else { return }

    guard let id = timelineProperties.selectedClip?.id else { return }
    deselect()
    do {
      if backgroundTrackBlocks.contains(id) {
        try engine.block.appendChild(to: pageID, child: id)
      } else {
        let insertedBlockTimeOffset = try engine.block.getTimeOffset(id)

        // Find the slot in the background track closest to the current time offset.
        var insertionIndex = backgroundTrackBlocks.count
        for (index, backgroundBlock) in backgroundTrackBlocks.enumerated() {
          let timeOffset = try engine.block.getTimeOffset(backgroundBlock)
          let duration = try engine.block.getDuration(backgroundBlock)
          if insertedBlockTimeOffset < timeOffset + duration / 2 {
            insertionIndex = index
            break
          }
        }
        try engine.block.insertChild(into: backgroundTrack, child: id, at: insertionIndex)
        try resetCropAndFillParentForBackgroundDrop(engine: engine, clipID: id)
      }

      addUndoStep()
      // Reparenting fires `.updated` events but no `.created` / `.destroyed` and the
      // page's direct children don't change, so `updateTimeline` won't flag the
      // datasource as dirty. Force a rebuild here so the moved clip leaves its old
      // track and lands in the new one — mirrors `finalizeExistingTrackDrop` after a
      // cross-track drop.
      cleanUpEmptyTracks()
      refreshTimeline()
    } catch {
      handleError(error)
    }
    Task {
      try await Task.sleep(for: .milliseconds(100))
      self.select(id: id)
    }
  }
}
