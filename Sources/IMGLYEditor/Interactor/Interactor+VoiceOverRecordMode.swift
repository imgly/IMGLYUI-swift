import AVFoundation
import Combine
import Foundation
import IMGLYEngine
import QuartzCore
@_spi(Internal) import IMGLYCore

enum VoiceOverRecordModeEntry {
  case create
  case addRecording
}

private struct VoiceOverRecordModeTargetResolution {
  let block: DesignBlockID
  let hasRecordedAudio: Bool
  let deletesTargetOnCancel: Bool
}

@MainActor
extension Interactor {
  func presentVoiceOverRecordMode(
    style: SheetStyle,
    preferredBlock: DesignBlockID? = nil,
    entry: VoiceOverRecordModeEntry = .create,
  ) async {
    await enterVoiceOverRecordMode(preferredBlock: preferredBlock, entry: entry)
    guard isVoiceOverRecordModeActive else { return }
    sheet = .init(.voiceover(style: style), .voiceover)
  }

  func enterVoiceOverRecordMode(
    preferredBlock: DesignBlockID? = nil,
    entry: VoiceOverRecordModeEntry = .create,
  ) async {
    guard let engine else { return }
    guard sceneMode == .video else { return }

    pause()

    do {
      let target = try resolveVoiceOverRecordModeTargetBlock(
        preferredBlock: preferredBlock,
        engine: engine,
        entry: entry,
      )
      let targetBlock = target.block
      let hasRecordedAudio = target.hasRecordedAudio

      if !hasRecordedAudio, engine.block.isValid(targetBlock) {
        try? engine.block.setDuration(targetBlock, duration: 0)
        try? engine.block.setTrimOffset(targetBlock, offset: 0)
      }

      voiceOverRecordCoordinator?.dispose()
      voiceOverRecordCoordinator = VoiceOverRecordCoordinator(
        interactor: self,
        targetBlock: targetBlock,
        hasRecordedAudio: hasRecordedAudio,
      )

      isVoiceOverRecordModeActive = true
      isVoiceOverRecordModeRecording = false
      hasVoiceOverRecordModeRecordedAudio = hasRecordedAudio
      isVoiceOverRecordModeMuteOtherAudio = true
      voiceOverRecordModeElapsedDuration = 0
      voiceOverRecordModeTarget = targetBlock
      voiceOverRecordModeDeletesTargetOnCancel = target.deletesTargetOnCancel
      voiceOverRecordModeSelectionToRestore = selection?.blocks.filter { engine.block.isValid($0) } ?? []
      ignoresNextVoiceOverSheetDismiss = false
      setVoiceOverRecordModeSelectionHidden(true)

      refreshTimeline()
      timelineProperties.requestScroll(to: targetBlock)
      select(id: targetBlock)
      timelineProperties.selectedClip = nil
    } catch {
      handleError(error)
    }
  }

  func toggleVoiceOverRecordModeRecording() async {
    guard isVoiceOverRecordModeActive else { return }
    if isVoiceOverRecordModeRecording {
      _ = await voiceOverRecordCoordinator?.stopAndPersist()
      return
    }

    let permission = await AudioRecordPermissionsManager.checkAudioRecordingPermission()
    guard permission != .denied else {
      error = .init("Microphone Access Needed",
                    message: "Please allow microphone access in Settings to record voiceovers.",
                    dismiss: false)
      return
    }

    let targetHasRecordedAudio = hasVoiceOverRecordModeRecordedAudio ||
      (voiceOverRecordModeTarget.map { voiceOverBlockHasAudioResource($0) } ?? false)
    if hasVoiceOverRecordModeRecordedAudio || targetHasRecordedAudio {
      // Keep previous recordings untouched by switching to a fresh voice-over draft track.
      await enterVoiceOverRecordMode(entry: .addRecording)
    }

    guard let coordinator = voiceOverRecordCoordinator else { return }
    await coordinator.startRecording()
  }

  func finishVoiceOverRecordMode() async {
    guard isVoiceOverRecordModeActive else { return }

    var didPersist = true
    if let coordinator = voiceOverRecordCoordinator, coordinator.isRecording {
      didPersist = await coordinator.stopAndPersist()
    }

    guard didPersist else { return }
    tearDownVoiceOverRecordMode(discardTarget: false)
  }

  func cancelVoiceOverRecordMode() async {
    guard isVoiceOverRecordModeActive else { return }

    if let coordinator = voiceOverRecordCoordinator {
      await coordinator.cancelAndDiscard()
    }

    tearDownVoiceOverRecordMode(discardTarget: true)
  }

  fileprivate func setVoiceOverRecordModeRecording(_ isRecording: Bool) {
    isVoiceOverRecordModeRecording = isRecording
  }

  fileprivate func setVoiceOverRecordModeHasRecordedAudio(_ hasRecordedAudio: Bool) {
    hasVoiceOverRecordModeRecordedAudio = hasRecordedAudio
  }

  fileprivate func setVoiceOverRecordModeSelectionHidden(_ hidden: Bool) {
    voiceOverRecordModeSelectionHidden = hidden
  }

  fileprivate func setVoiceOverRecordModeElapsedDuration(_ duration: TimeInterval) {
    voiceOverRecordModeElapsedDuration = duration
  }

  func toggleVoiceOverRecordModeMuteOtherAudio() {
    guard isVoiceOverRecordModeActive else { return }
    isVoiceOverRecordModeMuteOtherAudio.toggle()
    voiceOverRecordCoordinator?.applyMuteOtherAudio(isVoiceOverRecordModeMuteOtherAudio)
  }

  private func tearDownVoiceOverRecordMode(discardTarget: Bool) {
    let targetBlock = voiceOverRecordModeTarget
    let hasRecordedAudio = hasVoiceOverRecordModeRecordedAudio ||
      (targetBlock.map { voiceOverBlockHasAudioResource($0) } ?? false)
    let shouldDeleteTarget = !hasRecordedAudio || (discardTarget && voiceOverRecordModeDeletesTargetOnCancel)
    let persistedTargetBlock: DesignBlockID? = if shouldDeleteTarget {
      nil
    } else {
      targetBlock
    }
    let selectionToRestore = voiceOverRecordModeSelectionToRestore

    voiceOverRecordCoordinator?.dispose()
    voiceOverRecordCoordinator = nil

    if let targetBlock {
      if shouldDeleteTarget {
        if engine?.block.isValid(targetBlock) == true {
          delete(id: targetBlock)
          refreshTimeline()
        }
        restoreVoiceOverRecordModeSelection(selectionToRestore)
      } else {
        select(id: targetBlock)
      }
    } else if shouldDeleteTarget {
      restoreVoiceOverRecordModeSelection(selectionToRestore)
    }

    isVoiceOverRecordModeActive = false
    isVoiceOverRecordModeRecording = false
    hasVoiceOverRecordModeRecordedAudio = false
    isVoiceOverRecordModeMuteOtherAudio = true
    voiceOverRecordModeElapsedDuration = 0
    voiceOverRecordModeTarget = nil
    voiceOverRecordModeDeletesTargetOnCancel = true
    voiceOverRecordModeSelectionToRestore = []
    if shouldDeleteTarget {
      timelineProperties.selectedClip = nil
    }
    pendingVoiceOverRevealTarget = persistedTargetBlock
    setVoiceOverRecordModeSelectionHidden(false)
    ignoresNextVoiceOverSheetDismiss = true
    sheet.isPresented = false
  }

  private func resolveVoiceOverRecordModeTargetBlock(
    preferredBlock: DesignBlockID?,
    engine: Engine,
    entry _: VoiceOverRecordModeEntry,
  ) throws -> VoiceOverRecordModeTargetResolution {
    if let preferredBlock,
       engine.block.isValid(preferredBlock),
       isVoiceOverBlock(preferredBlock) {
      let hasRecordedAudio = voiceOverBlockHasAudioResource(preferredBlock)
      if !hasRecordedAudio {
        return .init(
          block: preferredBlock,
          hasRecordedAudio: hasRecordedAudio,
          deletesTargetOnCancel: !hasRecordedAudio,
        )
      }
    }

    if let draft = try findVoiceOverDraftOnCurrentPage(engine: engine) {
      return .init(block: draft, hasRecordedAudio: false, deletesTargetOnCancel: true)
    }

    let block = try createAudioBlock()
    if timelineProperties.currentPage != nil {
      try engine.block.setDuration(block, duration: 0)
      try engine.block.setTimeOffset(block, offset: 0)
    }
    try engine.block.setMetadata(block, key: "name", value: "Voiceover")
    return .init(block: block, hasRecordedAudio: false, deletesTargetOnCancel: true)
  }

  private func findVoiceOverDraftOnCurrentPage(engine: Engine) throws -> DesignBlockID? {
    guard let pageID = timelineProperties.currentPage else { return nil }
    let children = try engine.block.getChildren(pageID)
    for child in children where isVoiceOverBlock(child) && !voiceOverBlockHasAudioResource(child) {
      return child
    }
    return nil
  }

  private func isVoiceOverBlock(_ id: DesignBlockID) -> Bool {
    guard let engine, engine.block.isValid(id) else { return false }
    guard (try? engine.block.getType(id)) == DesignBlockType.audio.rawValue else { return false }
    return (try? engine.block.getKind(id)) == BlockKindKey.voiceover.rawValue
  }

  private func voiceOverBlockHasAudioResource(_ id: DesignBlockID) -> Bool {
    guard let engine, engine.block.isValid(id) else { return false }
    guard let audioURL = try? getAudioBlockURL(for: id) else { return false }
    if audioURL.scheme == "buffer" {
      return ((try? engine.editor.getBufferLength(url: audioURL))?.intValue ?? 0) > 0
    }
    return true
  }

  private func restoreVoiceOverRecordModeSelection(_ blocks: [DesignBlockID]) {
    guard let engine else {
      deselect()
      return
    }
    if let block = blocks.first(where: { engine.block.isValid($0) }) {
      select(id: block)
    } else {
      deselect()
    }
  }
}

@MainActor
final class VoiceOverRecordCoordinator: AudioRecordDelegate {
  private weak var interactor: Interactor?
  private let targetBlock: DesignBlockID
  private let audioProvider: AudioProvider
  private let targetHadRecordedAudioBeforeRecording: Bool
  private var audioManager: AudioRecordManager?

  private var cancellables = Set<AnyCancellable>()
  private var recordingStartedAt: Date?
  private var recordingStartOffset: Double = 0
  private var playbackWasActive = false
  private var isStopping = false
  private var wasLoopingPlaybackEnabled = false
  private var wasPageMuted = false
  private var recordingExtendsPageDuration = false
  private var recordingOriginalPageDuration: Double?
  private var progressTask: Task<Void, Never>?
  private var lastLiveWaveformRefreshAt: CFTimeInterval = 0
  private var hasReceivedAudioBuffer = false
  private var pendingAudioRecordError: AudioRecordError?

  private let playbackPauseStopGraceSeconds = 0.35
  private let playbackEndEpsilonSeconds = 0.02
  private let playbackExtensionBufferSeconds = 0.5
  private let liveWaveformRefreshIntervalSeconds: CFTimeInterval = 0.35
  private let initialAudioBufferTimeoutMilliseconds = 1500

  var isRecording = false

  init(interactor: Interactor, targetBlock: DesignBlockID, hasRecordedAudio: Bool) {
    self.interactor = interactor
    self.targetBlock = targetBlock
    targetHadRecordedAudioBeforeRecording = hasRecordedAudio
    audioProvider = AudioProvider(interactor: interactor)
    interactor.setVoiceOverRecordModeHasRecordedAudio(hasRecordedAudio)
    ensureAudioManager()
    observePlayback()
  }

  func startRecording() async {
    guard !isRecording else { return }
    guard let interactor else { return }
    guard let audioManager else {
      interactor.error = .init("Unable to Start Recording",
                               message: "The audio system could not be initialized.",
                               dismiss: false)
      return
    }

    if audioManager.status != .ready {
      let isReady = await waitForAudioSystemReady()
      guard isReady else {
        interactor.error = .init("Unable to Start Recording",
                                 message: "The audio system is still initializing. Please try again.",
                                 dismiss: false)
        return
      }
    }

    guard audioManager.status == .ready else {
      interactor.error = .init("Unable to Start Recording",
                               message: "The audio system is still initializing. Please try again.",
                               dismiss: false)
      return
    }

    do {
      try await audioProvider.setup(for: targetBlock)
    } catch {
      interactor.handleError(error)
      return
    }

    let playheadPositionSeconds = interactor.timelineProperties.player.playheadPosition.seconds
    audioProvider.resetOffsetPosition(for: playheadPositionSeconds, totalDuration: nil)
    let recordingStartOffset = max(0, playheadPositionSeconds)
    self.recordingStartOffset = recordingStartOffset

    if let engine = interactor.engine, engine.block.isValid(targetBlock) {
      try? engine.block.setTimeOffset(targetBlock, offset: recordingStartOffset)
      try? engine.block.setDuration(targetBlock, duration: 0)
      try? engine.block.setTrimOffset(targetBlock, offset: 0)
    }
    if let clip = interactor.timelineProperties.dataSource.findClip(id: targetBlock) {
      clip.timeOffset = .init(seconds: recordingStartOffset)
      clip.trimOffset = .init(seconds: 0)
      clip.duration = .init(seconds: 0)
      clip.allowsTrimming = false
    }
    applyLiveBufferState()

    if let currentPage = interactor.timelineProperties.currentPage,
       let engine = interactor.engine,
       engine.block.isValid(currentPage) {
      recordingExtendsPageDuration = interactor.timelineProperties.backgroundTrack == nil
      recordingOriginalPageDuration = try? engine.block.getDuration(currentPage)
      wasLoopingPlaybackEnabled = interactor.isLoopingPlaybackEnabled
      if wasLoopingPlaybackEnabled {
        interactor.toggleIsLoopingPlaybackEnabled()
      }
      wasPageMuted = (try? engine.block.isMuted(currentPage)) ?? false
      if interactor.isVoiceOverRecordModeMuteOtherAudio, !wasPageMuted {
        interactor.setPageMuted(true)
      }
      if recordingExtendsPageDuration {
        extendPageDurationIfNeeded(recordedDuration: 0)
      }
    }

    pendingAudioRecordError = nil
    hasReceivedAudioBuffer = false

    if let startError = audioManager.start() {
      restorePlaybackEnvironment()
      if recordingExtendsPageDuration {
        restoreOriginalPageDurationIfNeeded()
      }
      recordingExtendsPageDuration = false
      recordingOriginalPageDuration = nil
      audioManager.pause()
      handleAudioRecordError(startError)
      return
    }

    let didReceiveInitialAudioBuffer = await waitForInitialAudioBuffer()
    guard didReceiveInitialAudioBuffer else {
      audioManager.pause()
      interactor.pause()
      restorePlaybackEnvironment()
      interactor.setBlockMuted(targetBlock, muted: false)
      if recordingExtendsPageDuration {
        restoreOriginalPageDurationIfNeeded()
      }
      recordingExtendsPageDuration = false
      recordingOriginalPageDuration = nil
      await resetTargetAfterFailedRecordingAttempt()
      handleAudioRecordError(pendingAudioRecordError ?? .failedBuffer)
      return
    }

    interactor.setBlockMuted(targetBlock, muted: true)
    interactor.select(id: targetBlock)
    interactor.timelineProperties.selectedClip = nil
    interactor.setVoiceOverRecordModeSelectionHidden(true)
    interactor.play(seekToStartIfNeeded: false)

    recordingStartedAt = Date().addingTimeInterval(-audioProvider.recordedDuration)
    playbackWasActive = interactor.timelineProperties.player.isPlaying
    isRecording = true
    interactor.setVoiceOverRecordModeRecording(true)
    interactor.setVoiceOverRecordModeElapsedDuration(audioProvider.recordedDuration)
    lastLiveWaveformRefreshAt = 0
    updateRecordingProgress()
    startProgressUpdates()
  }

  func stopAndPersist() async -> Bool {
    guard isRecording, !isStopping else { return false }
    guard let interactor else { return false }
    isStopping = true
    defer {
      isStopping = false
      recordingExtendsPageDuration = false
      recordingOriginalPageDuration = nil
      pendingAudioRecordError = nil
    }
    isRecording = false
    interactor.setVoiceOverRecordModeRecording(false)
    stopProgressUpdates()

    audioManager?.pause()
    interactor.pause()

    restorePlaybackEnvironment()
    interactor.setBlockMuted(targetBlock, muted: false)

    let hasRecordedAudio: Bool
    do {
      hasRecordedAudio = try await audioProvider.endAudioBlock()
    } catch {
      interactor.handleError(error)
      return false
    }

    let finalDurationSeconds = max(
      interactor.voiceOverRecordModeElapsedDuration,
      audioProvider.recordedDuration,
    )
    if finalDurationSeconds > 0,
       let engine = interactor.engine,
       engine.block.isValid(targetBlock) {
      try? engine.block.setDuration(targetBlock, duration: finalDurationSeconds)
    }
    if let clip = interactor.timelineProperties.dataSource.findClip(id: targetBlock), finalDurationSeconds > 0 {
      clip.duration = CMTime(seconds: finalDurationSeconds)
      clip.footageURLString = try? interactor.getAudioBlockURL(for: targetBlock)?.absoluteString
      clip.footageDuration = clip.duration
      clip.isLoading = false
      clip.allowsTrimming = false
    }
    if recordingExtendsPageDuration {
      if hasRecordedAudio {
        syncPageDurationToContentEnd()
      } else {
        restoreOriginalPageDurationIfNeeded()
      }
    }

    guard hasRecordedAudio else {
      await resetTargetAfterFailedRecordingAttempt()
      interactor.error = .init("No Audio Captured",
                               message: "Recording did not produce any audio. Please try again.",
                               dismiss: false)
      return false
    }

    interactor.setVoiceOverRecordModeHasRecordedAudio(hasRecordedAudio)
    interactor.setVoiceOverRecordModeSelectionHidden(!hasRecordedAudio)

    interactor.voiceOverRecordModeDeletesTargetOnCancel = false
    interactor.refreshThumbnail(id: targetBlock)
    interactor.timelineProperties.requestScroll(to: targetBlock)
    interactor.select(id: targetBlock)
    interactor.addUndoStep()
    return true
  }

  func cancelAndDiscard() async {
    guard let interactor else { return }

    stopProgressUpdates()
    isStopping = false
    isRecording = false
    interactor.setVoiceOverRecordModeRecording(false)
    interactor.setVoiceOverRecordModeElapsedDuration(0)

    destroyAudioManager()
    interactor.pause()

    restorePlaybackEnvironment()
    interactor.setBlockMuted(targetBlock, muted: false)
    if recordingExtendsPageDuration {
      restoreOriginalPageDurationIfNeeded()
    }

    do {
      try await audioProvider.cancelChangesAudioBlock()
      if let clip = interactor.timelineProperties.dataSource.findClip(id: targetBlock) {
        clip.footageURLString = try? interactor.getAudioBlockURL(for: targetBlock)?.absoluteString
        clip.footageDuration = clip.duration
        clip.isLoading = false
        clip.allowsTrimming = false
      }
    } catch {
      interactor.handleError(error)
    }
  }

  func dispose() {
    cancellables.removeAll()
    stopProgressUpdates()
    destroyAudioManager()
  }

  func applyMuteOtherAudio(_ enabled: Bool) {
    guard isRecording, let interactor else { return }
    if enabled {
      if !wasPageMuted {
        interactor.setPageMuted(true)
      }
    } else if !wasPageMuted {
      interactor.setPageMuted(false)
    }
  }

  private func startProgressUpdates() {
    progressTask?.cancel()
    progressTask = Task { [weak self] in
      while let self, !Task.isCancelled {
        updateRecordingProgress()
        try? await Task.sleep(for: .milliseconds(33))
      }
    }
  }

  private func stopProgressUpdates() {
    progressTask?.cancel()
    progressTask = nil
  }

  private func waitForAudioSystemReady() async -> Bool {
    guard let audioManager else { return false }
    if audioManager.status == .ready {
      return true
    }

    for _ in 0 ..< 40 where audioManager.status != .ready {
      try? await Task.sleep(for: .milliseconds(50))
    }
    return audioManager.status == .ready
  }

  private func waitForInitialAudioBuffer() async -> Bool {
    if hasReceivedAudioBuffer {
      return true
    }

    for _ in 0 ..< (initialAudioBufferTimeoutMilliseconds / 50) {
      if hasReceivedAudioBuffer {
        return true
      }
      if pendingAudioRecordError != nil {
        return false
      }
      try? await Task.sleep(for: .milliseconds(50))
    }
    return hasReceivedAudioBuffer
  }

  private func updateRecordingProgress() {
    guard isRecording, !isStopping, let interactor, let recordingStartedAt else { return }
    let elapsedSeconds = max(0, Date().timeIntervalSince(recordingStartedAt))
    interactor.setVoiceOverRecordModeElapsedDuration(elapsedSeconds)
    if let engine = interactor.engine, engine.block.isValid(targetBlock) {
      try? engine.block.setDuration(targetBlock, duration: elapsedSeconds)
    }
    if let clip = interactor.timelineProperties.dataSource.findClip(id: targetBlock) {
      clip.duration = .init(seconds: elapsedSeconds)
    }
    if recordingExtendsPageDuration {
      extendPageDurationIfNeeded(recordedDuration: elapsedSeconds)
    }
  }

  private func observePlayback() {
    guard let interactor else { return }
    interactor.timelineProperties.player.$isPlaying
      .sink { [weak self] isPlaying in
        guard let self else { return }
        guard isRecording, !isStopping else { return }

        if isPlaying {
          playbackWasActive = true
          return
        }

        let elapsed = Date().timeIntervalSince(recordingStartedAt ?? Date())
        let playbackEnd = interactor.timelineProperties.timeline?.totalDuration.seconds ?? 0
        let playbackTime = interactor.timelineProperties.player.playheadPosition.seconds
        let reachedPlaybackEnd = playbackEnd > playbackEndEpsilonSeconds &&
          playbackTime >= playbackEnd - playbackEndEpsilonSeconds
        let currentPageDuration = (try? interactor.engine?.block
          .getDuration(interactor.timelineProperties.currentPage ?? 0)) ?? 0
        let reachedDynamicPageEnd = recordingExtendsPageDuration &&
          currentPageDuration > playbackEndEpsilonSeconds &&
          playbackTime >= currentPageDuration - playbackEndEpsilonSeconds
        let pauseDetected = playbackWasActive && elapsed >= playbackPauseStopGraceSeconds
        if pauseDetected, reachedDynamicPageEnd || reachedPlaybackEnd {
          extendPageDurationIfNeeded(recordedDuration: elapsed)
          interactor.play(seekToStartIfNeeded: false)
        }
      }
      .store(in: &cancellables)
  }

  func audioEngineDidEncounterError(_: AudioRecordManager, error: AudioRecordError) {
    pendingAudioRecordError = error
    guard isRecording else { return }
    destroyAudioManager()
    handleAudioRecordError(error)
  }

  func audioEngineDidReceiveBuffer(_: AudioRecordManager, buffer: AVAudioPCMBuffer, atTime _: AVAudioTime) {
    do {
      try audioProvider.setAudio(audioBufferData: buffer)
      hasReceivedAudioBuffer = true
      pendingAudioRecordError = nil
      interactor?.setVoiceOverRecordModeHasRecordedAudio(true)
      updateRecordingProgress()
      refreshLiveWaveformIfNeeded()
    } catch {
      interactor?.handleError(error)
    }
  }

  func engineWasInterrupted(_: AudioRecordManager) {
    Task { [weak self] in
      _ = await self?.stopAndPersist()
    }
  }

  func engineConfigurationHasChanged(_: AudioRecordManager) {
    Task { [weak self] in
      _ = await self?.stopAndPersist()
    }
  }

  private func restorePlaybackEnvironment() {
    guard let interactor else { return }
    if wasLoopingPlaybackEnabled {
      interactor.toggleIsLoopingPlaybackEnabled()
    }
    if !wasPageMuted {
      interactor.setPageMuted(false)
    }
  }

  private func extendPageDurationIfNeeded(recordedDuration: TimeInterval) {
    guard recordingExtendsPageDuration,
          let interactor,
          let engine = interactor.engine,
          let currentPage = interactor.timelineProperties.currentPage,
          engine.block.isValid(currentPage) else { return }

    let targetDuration = recordingStartOffset + max(0, recordedDuration) + playbackExtensionBufferSeconds
    let currentDuration = (try? engine.block.getDuration(currentPage)) ?? 0
    guard targetDuration > currentDuration + playbackEndEpsilonSeconds else { return }

    try? engine.block.setDuration(currentPage, duration: targetDuration)
    interactor.timelineProperties.timeline?.setTotalDuration(.init(seconds: targetDuration))
  }

  private func restoreOriginalPageDurationIfNeeded() {
    guard recordingExtendsPageDuration,
          let interactor,
          let engine = interactor.engine,
          let currentPage = interactor.timelineProperties.currentPage,
          let originalDuration = recordingOriginalPageDuration,
          engine.block.isValid(currentPage) else { return }

    try? engine.block.setDuration(currentPage, duration: originalDuration)
    interactor.timelineProperties.timeline?.setTotalDuration(.init(seconds: originalDuration))
  }

  private func syncPageDurationToContentEnd() {
    guard recordingExtendsPageDuration,
          let interactor,
          let engine = interactor.engine,
          let currentPage = interactor.timelineProperties.currentPage,
          engine.block.isValid(currentPage) else { return }

    let pageDuration = (try? engine.block.getDuration(currentPage)) ?? 0
    let timelineContentEnd = interactor.timelineProperties.dataSource.allClips()
      .map { clip in
        let clipDuration = clip.duration?.seconds ?? max(0, pageDuration - clip.timeOffset.seconds)
        return clip.timeOffset.seconds + max(0, clipDuration)
      }
      .max() ?? 0
    let targetBlockEnd = {
      guard engine.block.isValid(targetBlock) else { return 0.0 }
      let targetDuration = (try? engine.block.getDuration(targetBlock)) ?? 0
      let targetOffset = (try? engine.block.getTimeOffset(targetBlock)) ?? 0
      return targetOffset + max(0, targetDuration)
    }()
    let resolvedDuration = max(recordingOriginalPageDuration ?? 0, timelineContentEnd, targetBlockEnd)
    try? engine.block.setDuration(currentPage, duration: resolvedDuration)
    interactor.timelineProperties.timeline?.setTotalDuration(.init(seconds: resolvedDuration))
  }

  private func applyLiveBufferState() {
    guard let interactor,
          let bufferURL = audioProvider.currentBufferURL else { return }

    try? interactor.setAudioBlockURL(for: targetBlock, to: bufferURL)
    if let clip = interactor.timelineProperties.dataSource.findClip(id: targetBlock) {
      clip.footageURLString = bufferURL.absoluteString
      clip.footageDuration = clip.duration
      clip.isLoading = false
      clip.allowsTrimming = false
      clip.trimOffset = .zero
    }
    interactor.refreshThumbnail(id: targetBlock)
  }

  private func resetTargetAfterFailedRecordingAttempt() async {
    guard let interactor else { return }

    interactor.setVoiceOverRecordModeRecording(false)
    interactor.setVoiceOverRecordModeElapsedDuration(0)
    interactor.setVoiceOverRecordModeSelectionHidden(false)
    hasReceivedAudioBuffer = false
    try? await audioProvider.cancelChangesAudioBlock()

    if targetHadRecordedAudioBeforeRecording {
      interactor.setVoiceOverRecordModeHasRecordedAudio(true)
      if let clip = interactor.timelineProperties.dataSource.findClip(id: targetBlock) {
        clip.footageURLString = try? interactor.getAudioBlockURL(for: targetBlock)?.absoluteString
        clip.footageDuration = clip.duration
        clip.isLoading = false
        clip.allowsTrimming = false
      }
    } else {
      interactor.setVoiceOverRecordModeHasRecordedAudio(false)
      if let engine = interactor.engine, engine.block.isValid(targetBlock) {
        try? engine.block.setDuration(targetBlock, duration: 0)
        try? engine.block.setTrimOffset(targetBlock, offset: 0)
      }
      if let clip = interactor.timelineProperties.dataSource.findClip(id: targetBlock) {
        clip.duration = .zero
        clip.trimOffset = .zero
        clip.footageURLString = nil
        clip.footageDuration = .zero
        clip.isLoading = false
        clip.allowsTrimming = false
      }
    }

    interactor.refreshThumbnail(id: targetBlock)
    interactor.select(id: targetBlock)
    interactor.timelineProperties.selectedClip = nil
  }

  private func ensureAudioManager() {
    guard audioManager == nil else { return }
    let manager = AudioRecordManager()
    manager.delegate = self
    audioManager = manager
  }

  private func destroyAudioManager() {
    audioManager?.stop()
    audioManager = nil
  }

  private func handleAudioRecordError(_ error: AudioRecordError) {
    guard let interactor else { return }
    switch error {
    case .failedSetup:
      interactor.error = .init("Microphone Setup Failed",
                               message: "Failed to setup audio recording on this device.",
                               dismiss: false)
    case .failedBuffer:
      interactor.error = .init("Unable to Start Recording",
                               message: "No microphone audio was received. Please try again.",
                               dismiss: false)
    case .noInputChannel:
      interactor.error = .init("No Microphone Input",
                               message: "No microphone input channel is available on this device.",
                               dismiss: false)
    }
  }

  private func refreshLiveWaveformIfNeeded(force: Bool = false) {
    guard let interactor else { return }
    let now = CACurrentMediaTime()
    if !force, now - lastLiveWaveformRefreshAt < liveWaveformRefreshIntervalSeconds {
      return
    }
    lastLiveWaveformRefreshAt = now
    if let clip = interactor.timelineProperties.dataSource.findClip(id: targetBlock) {
      clip.footageDuration = clip.duration
      clip.isLoading = false
      clip.allowsTrimming = false
    }
    interactor.refreshThumbnail(id: targetBlock)
  }
}
