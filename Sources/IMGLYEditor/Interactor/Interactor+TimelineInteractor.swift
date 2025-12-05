import CoreMedia
import IMGLYCamera
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEngine
import SwiftUI

extension Interactor: TimelineInteractor {
  /// Configure the timeline.
  func configureTimeline() throws {
    guard let engine,
          sceneMode == .video else { return }

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
    NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.pauseIfNeeded()
      }
      .store(in: &cancellables)
  }

  func createBackgroundTrackIfNeeded() {
    guard let engine,
          timelineProperties.backgroundTrack == nil,
          sceneMode == .video,
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

    // Clean up empty tracks before processing events
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
    if position != timelineProperties.player.playheadPosition {
      timelineProperties.player.playheadPosition = position
    }
  }

  // MARK: Trimming

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
    addUndoStep()
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
        )

        addUndoStep()
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

  /// Creates a new clip representation in the timeline.
  private func createClip(id: DesignBlockID) {
    refresh(id: id, clip: nil)
  }

  // swiftlint:disable cyclomatic_complexity
  /// Creates a new clip or updates the passed existing clip representation in the timeline.
  private func refresh(id: DesignBlockID, clip existingClip: Clip?) {
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
      try setClipTrimOffsetProperties(clip)

      try setClipAVResourceProperties(clip)
      try setClipAudioProperties(clip)

      // If this is a freshly created clip, we need to add it to the timeline
      if existingClip == nil {
        let track = clip.isInBackgroundTrack ? timelineProperties.dataSource.backgroundTrack : Track()

        track.clips.append(clip)
        if !clip.isInBackgroundTrack {
          timelineProperties.dataSource.tracks.append(track)
        }
      } else {
        // Every clip change could affect the page’s total duration, so update durations and snap detents
        updateDurations()
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
  }

  // MARK: Clip's Set Properties

  private func setClipTimingProperties(_ clip: Clip) throws {
    guard let engine else { return }

    let durationSeconds = try engine.block.getDuration(clip.id)
    if durationSeconds > Double(Int.max) {
      clip.duration = (clip.clipType == .voiceOver) ? timelineProperties.timeline?.totalDuration : nil
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
  }

  private func setClipTrimOffsetProperties(_ clip: Clip) throws {
    guard let engine else { return }

    // Voiceovers are not meant to be trimmed, skip all trim operations
    guard clip.clipType != .voiceOver else {
      clip.allowsTrimming = false
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

    guard clip.clipType == .audio || clip.clipType == .video else {
      clip.footageDuration = nil
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

    guard clip.clipType == .audio || clip.clipType == .video else {
      clip.isMuted = false
      clip.audioVolume = 1.0
      return
    }

    clip.isMuted = try engine.block.isMuted(clip.trimmableID)
    clip.audioVolume = Double(try engine.block.getVolume(clip.trimmableID))
  }

  // swiftlint:enable cyclomatic_complexity

  /// Reloads the whole timeline from the engine state, purging the previous state.
  func refreshTimeline() {
    guard let engine,
          let pageID = timelineProperties.currentPage else { return }
    do {
      var blocks = try engine.block.getChildren(pageID)

      // Ensure that the scrubbing layer is never displayed in the timeline
      blocks.removeAll(where: { $0 == timelineProperties.scrubbingPreviewLayer })

      // Sort audio blocks to the bottom
      var audioBlocks = [DesignBlockID]()
      for (i, block) in blocks.enumerated().reversed() {
        let blockType = try engine.block.getType(block)
        if blockType == DesignBlockType.audio.rawValue {
          blocks.remove(at: i)
          audioBlocks.append(block)
        }
      }

      blocks.insert(contentsOf: audioBlocks.reversed(), at: 0)

      let tracks = try engine.block.find(byType: .track)
      for backgroundTrack in tracks where try engine.block.isPageDurationSource(backgroundTrack) {
        timelineProperties.backgroundTrack = backgroundTrack
      }

      if let backgroundTrack = timelineProperties.backgroundTrack,
         engine.block.isValid(backgroundTrack) {
        // Read background track blocks
        let backgroundTrackBlocks = try engine.block.getChildren(backgroundTrack)
        // Append the background track contents to the other blocks
        blocks.append(contentsOf: backgroundTrackBlocks)
      } else {
        timelineProperties.backgroundTrack = nil
      }

      // Remove all clips and tracks from the data source.
      timelineProperties.resetClips()

      // Then we walk through everything the engine gave us and recreate every clip in the timeline.
      for block in blocks {
        createClip(id: block)
      }

      updateTimelineSelectionFromCanvas()
    } catch {
      handleError(error)
    }
  }

  /// Updates the total duration of the page by reading it from the engine.
  private func updateDurations() {
    guard let engine,
          let timeline = timelineProperties.timeline,
          let pageID = timelineProperties.currentPage else { return }

    do {
      let pageDuration = try engine.block.getDuration(pageID)
      let totalDuration = CMTime(seconds: pageDuration)

      if totalDuration != CMTime(seconds: timeline.totalDuration.seconds) {
        timelineProperties.timeline?.setTotalDuration(totalDuration)
        // update clip elements that require to match duration of timeline
        timelineProperties.dataSource.foregroundClips()
          .filter { $0.clipType == .voiceOver }
          .forEach { $0.duration = totalDuration }
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
    guard let footageDuration = clip.footageDuration else { return }

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

    guard let footageDuration = clip.footageDuration else { return }
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
    // Prevent an infinite loop with the engine selection updates
    guard timelineProperties.selectedClip?.id != id else { return }
    guard let id else {
      // Passing `nil` deselects.
      deselect()
      return
    }
    if let clip = timelineProperties.dataSource.findClip(id: id) {
      timelineProperties.selectedClip = clip
      selectOnCanvas(id: clip.id)
      pause()
    }
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

  /// Select a clip in the timeline to match what’s selected on canvas.
  func updateTimelineSelectionFromCanvas() {
    guard sceneMode == .video else { return }
    guard let engine else { return }
    let selected = engine.block.findAllSelected()
    guard let id = selected.first else {
      deselect()
      return
    }

    // Allow selecting the page and do nothing in the timeline
    guard id != timelineProperties.currentPage else {
      timelineProperties.selectedClip = nil
      return
    }

    select(id: id)
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

  // MARK: Playback Control

  /// Start playback.
  func play() {
    guard let engine,
          let pageID = timelineProperties.currentPage else { return }
    do {
      let playbackTime = try engine.block.getPlaybackTime(pageID)
      let pageDuration = try engine.block.getDuration(pageID)

      if CMTime(seconds: playbackTime) >= CMTime(seconds: pageDuration) {
        setPlayheadPosition(CMTime(seconds: 0))
      }

      try engine.block.setPlaying(pageID, enabled: true)
    } catch {
      handleError(error)
    }
  }

  /// Pause playback if needed.
  private func pauseIfNeeded() {
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
    guard ((try? engine.block.getDuration(pageID)) ?? 0) > 0 else { return }
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
      let time = min(time, timeline.totalDuration)
      try engine.block.setPlaybackTime(pageID, time: time.seconds)
    } catch {
      handleError(error)
    }
  }

  private func setPlayheadPositionToEnding() {
    guard let engine,
          let totalDuration = timelineProperties.timeline?.totalDuration,
          let pageID = timelineProperties.currentPage else { return }
    do {
      try engine.block.setPlaybackTime(pageID, time: totalDuration.seconds)
    } catch {
      handleError(error)
    }
  }

  func clampPlayheadPositionToSelectedClip() {
    guard sceneMode == .video,
          let engine,
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

      try engine.block.setPlaybackTime(pageID, time: clampedTime.seconds)
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

  private func showVoiceOverSheet(style: SheetStyle) {
    sheet = .init(.voiceover(style: style), .voiceover)
  }

  func openVoiceOver(style: SheetStyle) {
    pause()

    Task {
      do {
        try engine?.block.deselectAll()
        // Ensure that the deselect event comes before opening the sheet, otherwise the sheet closes immediately.
        try await Task.sleep(for: .milliseconds(100))

        guard let duration = timelineProperties.timeline?.totalDuration.seconds, duration > 0 else {
          error = .init("Unable to Record Voiceover",
                        message: "Please add content to your timeline to start recording audio.",
                        dismiss: false)
          return
        }

        guard timelineProperties.dataSource.foregroundClips().allSatisfy({ $0.clipType != .voiceOver }) else {
          error = .init("Only One Voiceover Recording Possible",
                        message: "Please edit the existing voiceover.",
                        dismiss: false,
                        dismissTitle: "Cancel",
                        confirmTitle: "Edit",
                        confirmCallback: { [weak self] in
                          self?.error.isPresented = false
                          self?.editVoiceOver(style: style)
                        })
          return
        }

        showVoiceOverSheet(style: style)
      } catch {
        handleError(error)
      }
    }
  }

  func editVoiceOver(style: SheetStyle) {
    showVoiceOverSheet(style: style)
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
      var currentTimeOffset = totalDuration
      for recording in recordings {
        for (index, video) in recording.videos.enumerated() {
          // Add to asset library without invoking assetTapped()
          isAddingCameraRecording = true
          defer {
            isAddingCameraRecording = false
          }
          let asset = try await uploadVideo(to: videoUploadAssetSourceID) { video.url }

          guard let assetURL = asset.url else { continue }
          await addCameraVideo(
            fileURL: assetURL,
            rect: video.rect,
            duration: recording.duration,
            timeOffset: currentTimeOffset,
            addToBackgroundTrack: index == 0,
          )
        }
        // swiftlint:disable:next shorthand_operator
        currentTimeOffset = currentTimeOffset + recording.duration
      }
      addUndoStep()
    }
  }

  private func addCameraVideo(
    fileURL: URL,
    rect: CGRect,
    duration: CMTime,
    timeOffset: CMTime,
    addToBackgroundTrack: Bool,
  ) async {
    guard let engine,
          let pageID = timelineProperties.currentPage else { return }
    do {
      let id = try engine.block.create(.graphic)
      let rectShape = try engine.block.createShape(.rect)
      try engine.block.setShape(id, shape: rectShape)

      if addToBackgroundTrack {
        createBackgroundTrackIfNeeded()
      }

      if addToBackgroundTrack,
         let backgroundTrack = timelineProperties.backgroundTrack {
        try engine.block.appendChild(to: backgroundTrack, child: id)
      } else {
        try engine.block.appendChild(to: pageID, child: id)
      }
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

  func openSystemCamera(_ assetSourceIDs: [MediaType: String]) {
    pause()
    uploadAssetSourceIDs = assetSourceIDs
    isSystemCameraShown = true
    sheet.content = .clip // Set to clip to add to background track
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
        if try engine.block.isScopeEnabled(id, scope: .key(.layerCrop)),
           try engine.block.getKind(id) != BlockKindKey.sticker.rawValue {
          try engine.block.resetCrop(id)
          try engine.block.fillParent(id)
        }
      }

      addUndoStep()
    } catch {
      handleError(error)
    }
    Task {
      try await Task.sleep(for: .milliseconds(100))
      self.select(id: id)
    }
  }
}
