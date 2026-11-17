import Foundation
import IMGLYEngine
import SwiftUI
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI

extension ClipSpeedOptions {
  @MainActor
  class ViewModel: ObservableObject {
    @Published var showNoAudioToast = false

    private let interactor: Interactor
    private let timelineConfiguration: TimelineConfiguration
    private var selectionID: DesignBlockID?
    private var wasOverAudioCutoff = false
    private var toastTask: Task<Void, Never>?

    init(interactor: Interactor, timelineConfiguration: TimelineConfiguration) {
      self.interactor = interactor
      self.timelineConfiguration = timelineConfiguration
    }

    var state: ClipSpeedState {
      guard let id = selectionID, let engine = interactor.engine else {
        return .init(
          speed: 1,
          isEnabled: false,
          durationSeconds: nil,
          isVideo: false,
          isAudio: false,
          maxSpeed: ClipSpeedDefaults.maxSpeed,
        )
      }
      guard let playbackBlock = playbackControlBlock(engine: engine, designBlock: id) else {
        return .init(
          speed: 1,
          isEnabled: false,
          durationSeconds: nil,
          isVideo: false,
          isAudio: false,
          maxSpeed: ClipSpeedDefaults.maxSpeed,
        )
      }

      let speed = (try? engine.block.getPlaybackSpeed(playbackBlock)) ?? 1
      let blockType = try? engine.block.getType(id)
      let isAudio = blockType == Interactor.BlockType.audio.rawValue
      let durationSeconds: Double? = if (try? engine.block.supportsDuration(id)) == true {
        try? engine.block.getDuration(id)
      } else {
        nil
      }
      let playbackFillType = try? FillType(rawValue: engine.block.getType(playbackBlock))
      let maxSpeed = isAudio ? ClipSpeedDefaults.audioMaxSpeed : ClipSpeedDefaults.maxSpeed

      return .init(
        speed: speed,
        isEnabled: true,
        durationSeconds: durationSeconds,
        isVideo: playbackFillType == .video,
        isAudio: isAudio,
        maxSpeed: maxSpeed,
      )
    }

    var speedBinding: Binding<Float> {
      Binding(
        get: { self.state.speed },
        set: { self.applySpeed($0) },
      )
    }

    var durationBinding: Binding<Double> {
      Binding(
        get: { self.state.durationSeconds ?? 0 },
        set: { self.applyDuration($0) },
      )
    }

    /// The valid duration range at the current speed. `0...0` when duration
    /// does not apply.
    var durationBounds: ClosedRange<Double> {
      let state = state
      guard let durationSeconds = state.durationSeconds else { return 0 ... 0 }
      let baseDuration = durationSeconds * Double(state.speed)
      let minDuration = max(
        baseDuration / Double(state.maxSpeed),
        timelineConfiguration.minClipDuration.seconds,
      )
      // Never let a large configured `minClipDuration` push the lower bound
      // past the upper one: `ClosedRange` traps on construction if it did.
      let maxDuration = max(baseDuration / Double(ClipSpeedDefaults.minSpeed), minDuration)
      return minDuration ... maxDuration
    }

    func updateSelection(_ id: DesignBlockID?) {
      selectionID = id
      wasOverAudioCutoff = false
    }

    func durationEnabled(for state: ClipSpeedState) -> Bool {
      state.isEnabled && state.durationSeconds != nil
    }

    func isOverAudioCutoff(for state: ClipSpeedState) -> Bool {
      state.isEnabled && state.isVideo && state.speed > ClipSpeedDefaults.audioSpeedCutoff
    }

    func handleAudioCutoffChange(isOver: Bool) {
      if isOver, !wasOverAudioCutoff {
        showAudioToast()
      }
      wasOverAudioCutoff = isOver
    }

    func dismissToast() {
      toastTask?.cancel()
      withAnimation(.easeInOut(duration: 0.2)) {
        showNoAudioToast = false
      }
    }

    /// Call from the rows' `onEditingChanged`, so a hold adds one undo step.
    func addUndoStep() {
      interactor.addUndoStep()
    }

    private func applySpeed(_ newSpeed: Float) {
      guard let id = selectionID, let engine = interactor.engine else { return }
      guard let playbackBlock = playbackControlBlock(engine: engine, designBlock: id) else { return }

      do {
        if try engine.block.supportsDuration(id), newSpeed > 0 {
          let currentDuration = try engine.block.getDuration(id)
          let currentSpeed = try engine.block.getPlaybackSpeed(playbackBlock)
          let newDuration = (currentDuration * Double(currentSpeed)) / Double(newSpeed)
          if !isParentBackgroundTrack(engine: engine, block: id),
             detectClipCollision(engine: engine, block: id, newDuration: newDuration) {
            try moveClipToNewTrack(engine: engine, block: id)
          }
        }
        try engine.block.setPlaybackSpeed(playbackBlock, speed: newSpeed)
        interactor.objectWillChange.send()
      } catch {
        interactor.handleError(error)
      }
    }

    /// `newDuration` is already clamped to `durationBounds`, so the `> 0` guard
    /// covers only a configured `minClipDuration` of zero or less.
    private func applyDuration(_ newDuration: Double) {
      let state = state
      guard state.isEnabled, let durationSeconds = state.durationSeconds, newDuration > 0 else { return }
      let baseDuration = durationSeconds * Double(state.speed)
      let newSpeed = NumberStepperMath.clamped(
        baseDuration / newDuration,
        to: Double(ClipSpeedDefaults.minSpeed) ... Double(state.maxSpeed),
      )
      applySpeed(Float(newSpeed))
    }

    private func playbackControlBlock(engine: Engine, designBlock: DesignBlockID) -> DesignBlockID? {
      if (try? engine.block.supportsPlaybackControl(designBlock)) == true {
        return designBlock
      }
      if (try? engine.block.supportsFill(designBlock)) == true {
        if let fill = try? engine.block.getFill(designBlock),
           (try? engine.block.supportsPlaybackControl(fill)) == true {
          return fill
        }
      }
      return nil
    }

    private func isParentBackgroundTrack(engine: Engine, block: DesignBlockID) -> Bool {
      guard let track = getParentTrack(engine: engine, block: block) else { return false }
      return (try? engine.block.isPageDurationSource(track)) == true
    }

    private func detectClipCollision(engine: Engine, block: DesignBlockID, newDuration: Double) -> Bool {
      guard let track = getParentTrack(engine: engine, block: block) else { return false }
      guard let trackChildren = try? engine.block.getChildren(track), trackChildren.count > 1 else { return false }

      guard let currentStartTime = try? engine.block.getTimeOffset(block) else { return false }
      guard let currentDuration = try? engine.block.getDuration(block) else { return false }
      let currentEndTime = currentStartTime + currentDuration
      let newEndTime = currentStartTime + newDuration

      let nextClipStartTime = trackChildren
        .filter { $0 != block }
        .compactMap { try? engine.block.getTimeOffset($0) }
        .filter { $0 > currentStartTime }
        .min()

      guard let nextClipStartTime else { return false }

      // A transition intentionally overlaps the outgoing and incoming clips. Keep
      // that pair in its track; only separate the clip when changing its speed
      // introduces an overlap that did not exist before.
      return currentEndTime <= nextClipStartTime && newEndTime > nextClipStartTime
    }

    private func moveClipToNewTrack(engine: Engine, block: DesignBlockID) throws {
      guard let page = try engine.scene.getCurrentPage() else { return }
      guard let currentTrack = getParentTrack(engine: engine, block: block) else { return }

      let pageChildren = try engine.block.getChildren(page)
      guard let trackIndex = pageChildren.firstIndex(of: currentTrack) else { return }

      let currentTimeOffset = try engine.block.getTimeOffset(block)
      let newTrack = try engine.block.create(.track)
      try engine.block.insertChild(into: page, child: newTrack, at: trackIndex + 1)
      try engine.block.setBool(newTrack, property: "track/automaticallyManageBlockOffsets", value: false)
      try engine.block.appendChild(to: newTrack, child: block)
      try engine.block.setTimeOffset(block, offset: currentTimeOffset)
    }

    private func getParentTrack(engine: Engine, block: DesignBlockID) -> DesignBlockID? {
      var parent = try? engine.block.getParent(block)
      while let currentParent = parent, engine.block.isValid(currentParent) {
        if (try? engine.block.getType(currentParent)) == DesignBlockType.track.rawValue {
          return currentParent
        }
        parent = try? engine.block.getParent(currentParent)
      }
      return nil
    }

    private func showAudioToast() {
      toastTask?.cancel()
      withAnimation(.easeInOut(duration: 0.2)) {
        showNoAudioToast = true
      }
      toastTask = Task { @MainActor in
        try? await Task.sleep(nanoseconds: 3_500_000_000)
        withAnimation(.easeInOut(duration: 0.2)) {
          showNoAudioToast = false
        }
      }
    }
  }
}
