import CoreMedia
@_spi(Internal) import IMGLYCore
import IMGLYEngine

/// Plays the short, focused playback preview used after applying an animation or transition.
@MainActor
final class AnimationPreview {
  enum Mode {
    case `in`
    case out
    case loop
  }

  private var task: Task<Void, Never>?
  private var previewID = 0
  private var isPlaying = false

  func playAnimation(engine: Engine, pageID: DesignBlockID, clip: DesignBlockID, mode: Mode) {
    let animation: DesignBlockID? = switch mode {
    case .in: try? engine.block.getInAnimation(clip)
    case .out: try? engine.block.getOutAnimation(clip)
    case .loop: try? engine.block.getLoopAnimation(clip)
    }
    guard let animation,
          engine.block.isValid(animation),
          let duration = try? engine.block.getDuration(animation) else { return }
    play(engine: engine, pageID: pageID, clip: clip, duration: duration, endAligned: mode == .out)
  }

  func playTransition(engine: Engine, pageID: DesignBlockID, outgoing: DesignBlockID) {
    guard let incoming = transitionIncomingClip(engine: engine, outgoing: outgoing) else { return }
    let duration = transitionOverlap(engine: engine, outgoing: outgoing, incoming: incoming).seconds
    play(engine: engine, pageID: pageID, clip: outgoing, duration: duration, endAligned: true)
  }

  func stop(engine: Engine, pageID: DesignBlockID) {
    previewID += 1
    let hadPreview = task != nil || isPlaying
    task?.cancel()
    task = nil
    if hadPreview, (try? engine.block.isPlaying(pageID)) == true {
      try? engine.block.setPlaying(pageID, enabled: false)
    }
    isPlaying = false
  }

  private func play(
    engine: Engine,
    pageID: DesignBlockID,
    clip: DesignBlockID,
    duration: Double,
    endAligned: Bool,
  ) {
    // UI test screenshots are flaky while preview playback is running, so disable it during testing.
    guard !ProcessInfo.isUITesting else { return }

    stop(engine: engine, pageID: pageID)
    guard duration > 0,
          let clipOffset = try? engine.block.getTimeOffset(clip),
          let clipDuration = try? engine.block.getDuration(clip) else { return }

    let previewDuration = min(duration, clipDuration)
    let start = endAligned ? clipOffset + clipDuration - previewDuration : clipOffset
    try? engine.block.setPlaying(pageID, enabled: false)
    try? engine.block.setPlaybackTime(pageID, time: start)

    let id = previewID + 1
    previewID = id
    task = Task { [weak self] in
      try? await Task.sleep(for: .milliseconds(100))
      guard let self, id == previewID, !Task.isCancelled else { return }
      try? engine.block.setPlaying(pageID, enabled: true)
      isPlaying = true
      try? await Task.sleep(for: .seconds(previewDuration))
      guard id == previewID, isPlaying, !Task.isCancelled else { return }
      try? engine.block.setPlaying(pageID, enabled: false)
      isPlaying = false
      task = nil
    }
  }
}
