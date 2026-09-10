import Foundation
import IMGLYEngine
import SwiftUI
@_spi(Internal) import IMGLYCore

extension ClipSpeedOptions {
  @MainActor
  class ViewModel: ObservableObject {
    @Published var speedInput: String = ""
    @Published var durationInput: String = ""
    @Published var showNoAudioToast = false

    private let interactor: Interactor
    private let timelineConfiguration: TimelineConfiguration
    private var selectionID: DesignBlockID?
    private var focusedField: ClipSpeedField?
    private var lastFocusedField: ClipSpeedField?
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

    var speedInputBinding: Binding<String> {
      Binding(
        get: { self.speedInput },
        set: { self.speedInput = self.sanitizeDecimalInput($0, maxDecimals: ClipSpeedDefaults.speedInputDecimals) },
      )
    }

    var durationInputBinding: Binding<String> {
      Binding(
        get: { self.durationInput },
        set: { self.durationInput = self.sanitizeDecimalInput($0, maxDecimals: ClipSpeedDefaults.durationInputDecimals)
        },
      )
    }

    func updateSelection(_ id: DesignBlockID?) {
      selectionID = id
      wasOverAudioCutoff = false
      syncInputs(force: true)
    }

    func durationEnabled(for state: ClipSpeedState) -> Bool {
      state.isEnabled && state.durationSeconds != nil
    }

    func isOverAudioCutoff(for state: ClipSpeedState) -> Bool {
      state.isEnabled && state.isVideo && state.speed > ClipSpeedDefaults.audioSpeedCutoff
    }

    func handleSpeedSelection(_ newSpeed: Float) {
      applySpeed(newSpeed)
      syncInputs(with: state)
    }

    func handleAudioCutoffChange(isOver: Bool) {
      if isOver, !wasOverAudioCutoff {
        showAudioToast()
      }
      wasOverAudioCutoff = isOver
    }

    func handleFocusChange(_ newField: ClipSpeedField?) {
      if lastFocusedField == .speed, newField != .speed {
        commitSpeedInput()
      }
      if lastFocusedField == .duration, newField != .duration {
        commitDurationInput()
      }
      lastFocusedField = newField
      focusedField = newField
    }

    func syncInputs(force: Bool = false) {
      syncInputs(with: state, force: force)
    }

    func previousStepValue(_ current: Float) -> Float? {
      if current <= ClipSpeedDefaults.minSpeed + ClipSpeedDefaults.compareEpsilon { return nil }
      let stepIndex = current / ClipSpeedDefaults.step
      let targetStep: Double = if isOnStep(current) {
        Double((stepIndex - 1).rounded(.down))
      } else {
        floor(Double(stepIndex))
      }
      let previous = Float(targetStep) * ClipSpeedDefaults.step
      return max(previous, ClipSpeedDefaults.minSpeed)
    }

    func nextStepValue(_ current: Float) -> Float? {
      let maxSpeed = state.maxSpeed
      if current >= maxSpeed - ClipSpeedDefaults.compareEpsilon { return nil }
      let stepIndex = current / ClipSpeedDefaults.step
      let targetStep: Double = if isOnStep(current) {
        Double((stepIndex + 1).rounded(.up))
      } else {
        ceil(Double(stepIndex))
      }
      let next = Float(targetStep) * ClipSpeedDefaults.step
      return min(next, maxSpeed)
    }

    func dismissToast() {
      toastTask?.cancel()
      withAnimation(.easeInOut(duration: 0.2)) {
        showNoAudioToast = false
      }
    }

    private func syncInputs(with state: ClipSpeedState, force: Bool = false) {
      if force || focusedField != .speed {
        speedInput = formatSpeedValue(state.speed)
      }
      if force || focusedField != .duration {
        durationInput = state.durationSeconds.map(formatDurationValue) ?? ""
      }
    }

    private func commitSpeedInput() {
      let state = state
      guard state.isEnabled else {
        speedInput = formatSpeedValue(state.speed)
        return
      }
      guard let parsedSpeed = parseDecimalInput(speedInput) else {
        speedInput = formatSpeedValue(state.speed)
        return
      }
      let clampedSpeed = min(max(parsedSpeed, Double(ClipSpeedDefaults.minSpeed)), Double(state.maxSpeed))
      let newSpeed = Float(clampedSpeed)
      applySpeed(newSpeed)
      speedInput = formatSpeedValue(newSpeed)
    }

    private func commitDurationInput() {
      let state = state
      guard state.isEnabled, let durationSeconds = state.durationSeconds else {
        durationInput = state.durationSeconds.map(formatDurationValue) ?? ""
        return
      }
      let baseDuration = durationSeconds * Double(state.speed)
      let minDuration = max(
        baseDuration / Double(state.maxSpeed),
        timelineConfiguration.minClipDuration.seconds,
      )
      let maxDuration = baseDuration / Double(ClipSpeedDefaults.minSpeed)
      let fallbackDuration = formatDurationValue(durationSeconds)

      guard let parsedDuration = parseDecimalInput(durationInput), parsedDuration > 0 else {
        durationInput = fallbackDuration
        return
      }

      let clampedDuration = min(max(parsedDuration, minDuration), maxDuration)
      let newSpeed = (baseDuration / clampedDuration)
        .clamped(to: Double(ClipSpeedDefaults.minSpeed) ... Double(state.maxSpeed))

      applySpeed(Float(newSpeed))
      durationInput = formatDurationValue(clampedDuration)
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
        interactor.addUndoStep()
        interactor.objectWillChange.send()
      } catch {
        interactor.handleError(error)
      }
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
      let newEndTime = currentStartTime + newDuration

      let nextClipStartTime = trackChildren
        .filter { $0 != block }
        .compactMap { try? engine.block.getTimeOffset($0) }
        .filter { $0 > currentStartTime }
        .min()

      guard let nextClipStartTime else { return false }
      return newEndTime > nextClipStartTime
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

    private func formatSpeedValue(_ speed: Float) -> String {
      let formatter = NumberFormatter()
      formatter.locale = Locale.current
      formatter.numberStyle = .decimal
      formatter.minimumFractionDigits = ClipSpeedDefaults.speedInputDecimals
      formatter.maximumFractionDigits = ClipSpeedDefaults.speedInputDecimals
      formatter.usesGroupingSeparator = false
      return formatter.string(from: NSNumber(value: speed)) ?? ""
    }

    private func formatDurationValue(_ durationSeconds: Double) -> String {
      let formatter = NumberFormatter()
      formatter.locale = Locale.current
      formatter.numberStyle = .decimal
      formatter.minimumFractionDigits = 2
      formatter.maximumFractionDigits = ClipSpeedDefaults.durationInputDecimals
      formatter.usesGroupingSeparator = false
      return formatter.string(from: NSNumber(value: durationSeconds)) ?? ""
    }

    private func sanitizeDecimalInput(_ input: String, maxDecimals: Int) -> String {
      let filtered = input.filter { $0.isNumber || $0 == "." || $0 == "," }
      guard let separatorIndex = filtered.firstIndex(where: { $0 == "." || $0 == "," }) else {
        return filtered
      }
      let separator = filtered[separatorIndex]
      let prefix = String(filtered[..<separatorIndex])
      let suffix = filtered[filtered.index(after: separatorIndex)...]
        .filter(\.isNumber)
        .prefix(maxDecimals)
      return suffix.isEmpty ? "\(prefix)\(separator)" : "\(prefix)\(separator)\(suffix)"
    }

    private func parseDecimalInput(_ input: String) -> Double? {
      Double(input.replacingOccurrences(of: ",", with: "."))
    }

    private func isOnStep(_ value: Float) -> Bool {
      let stepIndex = value / ClipSpeedDefaults.step
      return abs(stepIndex - round(stepIndex)) <= ClipSpeedDefaults.compareEpsilon
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

private extension Comparable {
  func clamped(to range: ClosedRange<Self>) -> Self {
    min(max(self, range.lowerBound), range.upperBound)
  }
}
