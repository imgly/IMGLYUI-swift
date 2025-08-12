import AVFoundation
import Combine
import SwiftUI
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI

enum VoiceOverState: Equatable {
  case idle, recording, playing, error(String), loading, ended
}

enum RecordingState {
  case start, pause, resume, replace
}

enum VoiceOverMode {
  case new
  case edit
}

@MainActor
protocol VoiceOverViewModelProtocol: ObservableObject {
  var state: VoiceOverState { get }
  var mode: VoiceOverMode { get }
  var recordingButtonState: RecordingState { get set }
  var isRecordingEnabled: Bool { get set }
  var isPlayingEnabled: Bool { get }
  var isSoundMuted: Bool { get }
  var isShowingPermissionsAlertForMicrophone: Bool { get set }
  var alreadyRecordedAudio: Bool { get }
  var audioWaves: [Int: Wave] { get }

  func pauseAnyActivity()

  func toggleAction() async
  func togglePlay()
  func toggleExternalAudio()
  func doneAction()
  func cancelAction()
}

@MainActor
final class VoiceOverViewModel: ObservableObject {
  private enum Localization {
    static let errorAudioHardwareSetup = "Failed to setup audio recording on device"
    static let errorAudioEngineSetup = "Failed to setup audio environment"
    static let errorAudioEngineCreateFile = "Failed to create audio object"
    static let errorEnvironmentRecording = "The environment is still being set up. Please try again shortly."
  }

  // MARK: - Properties

  @Published var isShowingPermissionsAlertForMicrophone = false
  @Published var state: VoiceOverState = .idle {
    didSet {
      handleStateChange(from: oldValue, to: state)
    }
  }

  @Published var recordingButtonState: RecordingState = .start
  @Published var isPlayingEnabled: Bool = false
  @Published var isRecordingEnabled: Bool = true
  @Published var isSoundMuted: Bool = true
  @Published var audioWaves: [Int: Wave] = [:]
  var alreadyRecordedAudio: Bool = false
  var mode: VoiceOverMode = .new

  private let audioWaveQueue = DispatchQueue(label: "thumbnailTask")
  private var thumbnailTimer: PrecisionTimer?

  // Device Recorder
  private var audioManager: AudioRecordManagerProvider

  // Audio Interactor
  private var audioProvider: VoiceOverAudioProvider
  private var player: Player
  private var interactor: AnyTimelineInteractor

  private var totalDurationSeconds: Double = 0
  private var numberOfSamplesToRequestByInterval: Int = 0
  private var durationEachIntervalToRequestSamples: Double = 0
  private var lastEndIntervalRequestedInSeconds: TimeInterval?
  private var totalOfsamples: Int = 0

  private var shouldResetLoopingInteractor: Bool = false // in the end we should set the timeline properties

  private var didEnterBackgroundNotificationPublisher: AnyCancellable?
  private var willResignActiveNotificationPublisher: AnyCancellable?
  private var cancellables = Set<AnyCancellable>()

  // MARK: - Initializers

  init(
    audioBlock: Interactor.BlockID? = nil,
    audioManager: AudioRecordManagerProvider,
    audioProvider: VoiceOverAudioProvider,
    interactor: AnyTimelineInteractor,
    player: Player
  ) {
    self.interactor = interactor
    self.audioManager = audioManager
    self.audioProvider = audioProvider
    self.player = player

    totalDurationSeconds = interactor.timelineProperties.timeline?.totalDuration.seconds ?? 0

    setupSubscriptions()
    setup()
    setup(with: audioBlock)
    configureNotifications()
  }

  // MARK: - Methods

  private func cleanUp() {
    audioManager.stop()
    interactor.pause()
    thumbnailTimer?.stop()
    thumbnailTimer = nil
    cancellables.removeAll()

    resetStates()
  }

  private func resetStates() {
    if shouldResetLoopingInteractor {
      interactor.toggleIsLoopingPlaybackEnabled()
    }
    if isSoundMuted {
      interactor.setPageMuted(false)
    }
  }

  private func setupSubscriptions() {
    audioManager.delegate = self

    player.$playheadPosition
      .sink { [weak self] _ in self?.checkButtonState() }
      .store(in: &cancellables)

    player.$playheadPosition
      .filter { [weak self] newValue in
        guard let self else { return false }
        return newValue.seconds >= totalDurationSeconds
      }
      .sink { [weak self] _ in self?.reachedEndDuration() }
      .store(in: &cancellables)
  }

  private func setup() {
    // we need to reset any state we change in the interactor
    if interactor.isLoopingPlaybackEnabled == true {
      interactor.toggleIsLoopingPlaybackEnabled()
      shouldResetLoopingInteractor = true
    }

    if isSoundMuted {
      interactor.setPageMuted(true)
    }

    // calculate the number of samples to request in each interval and the duration between each request
    let timelineTotalWidth = interactor.timelineProperties.timeline?.totalWidth ?? 0

    let widthForEachWave = (VoiceOverConfiguration.waveSizeWidth + VoiceOverConfiguration.waveSpaceSizeWidth)
    let totalNumberWavesValues = Int(floor(timelineTotalWidth / widthForEachWave))
    let numberAndDurationBySample = calculateOptimalIntervalsAndValues(for: totalNumberWavesValues,
                                                                       totalDuration: totalDurationSeconds)

    numberOfSamplesToRequestByInterval = numberAndDurationBySample.valuesPerInterval
    durationEachIntervalToRequestSamples = numberAndDurationBySample.intervalDuration
    totalOfsamples = totalNumberWavesValues

    // we use this timer in order to now when tom make request to the thumbnails
    thumbnailTimer = PrecisionTimer(interval: durationEachIntervalToRequestSamples, callback: {
      self.fetchAudioThumbnails()
    })
  }

  func setup(with audioBlock: Interactor.BlockID?) {
    // if an audioBlock is passed we should we should loaded from engine
    if let audioBlock {
      mode = .edit
      state = .loading
      Task {
        do {
          try await audioProvider.setup(for: audioBlock)
          fetchAudioThumbnails(timeBegin: 0, timeEnd: totalDurationSeconds, numberOfSamples: totalOfsamples)
          // since the thumbnails will fill the all duration we can set the button on replace state
          recordingButtonState = .replace
          isPlayingEnabled = true
        } catch {
          state = .error(Localization.errorAudioEngineSetup)
        }
      }
    }
  }

  // MARK: - Thumbnails

  private func fetchAudioThumbnails(timeBegin: Double, timeEnd: Double, numberOfSamples: Int) {
    Task { [weak self] in
      guard let self else { return }
      do {
        let newAudioValues = try await audioProvider.loadAudioThumbnails(timeBegin: timeBegin,
                                                                         timeEnd: timeEnd,
                                                                         numberOfSamples: numberOfSamples)

        for try await newValue in newAudioValues {
          if Task.isCancelled { return }

          audioWaveQueue.sync {
            var barInitialPos = self.wavePosition(for: timeBegin)

            for sample in newValue.samples {
              if let wave = self.audioWaves[barInitialPos] {
                if wave.recorded {
                  wave.value = (wave.value + sample) / 2
                } else {
                  wave.recorded = self.alreadyRecordedAudio && self.state == .recording
                  wave.value = sample
                }
              } else {
                let newWave = Wave(
                  value: sample,
                  recorded: (self.alreadyRecordedAudio && self.state == .recording) ? true : false,
                  position: barInitialPos,
                )
                self.audioWaves[barInitialPos] = newWave
              }
              barInitialPos += 1
            }

            if self.state == .loading {
              self.state = .idle
            }
          }
        }
      } catch {
        if state == .loading {
          state = .error(Localization.errorAudioEngineCreateFile)
        }
      }
    }
  }

  private func fetchAudioThumbnails(timeBegin: Double, timeEnd: Double) {
    let duration = abs(timeEnd - timeBegin)
    let numberOfSamples = Int(ceil((Double(numberOfSamplesToRequestByInterval) * duration) /
        durationEachIntervalToRequestSamples))
    if numberOfSamples > 0 {
      fetchAudioThumbnails(timeBegin: timeBegin, timeEnd: timeEnd, numberOfSamples: numberOfSamples)
    }
  }

  private func fetchAudioThumbnails() {
    let timeBegin = lastEndIntervalRequestedInSeconds ?? max(
      0,
      player.playheadPosition.seconds - durationEachIntervalToRequestSamples,
    )
    let timeEnd = timeBegin + durationEachIntervalToRequestSamples
    lastEndIntervalRequestedInSeconds = timeEnd

    fetchAudioThumbnails(timeBegin: timeBegin,
                         timeEnd: timeEnd,
                         numberOfSamples: numberOfSamplesToRequestByInterval)
  }

  // MARK: - Helper Methods

  private func wavePosition(for time: Double) -> Int {
    Int((time * Double(totalOfsamples) / totalDurationSeconds).rounded(.toNearestOrAwayFromZero))
  }

  private func calculateOptimalIntervalsAndValues(for totalValues: Int,
                                                  totalDuration: Double) -> (valuesPerInterval: Int,
                                                                             intervalDuration: Double) {
    guard totalValues > 0, totalDuration > 0 else {
      return (0, 0)
    }

    var numberOfIntervals = max(Int(ceil(totalDuration / VoiceOverConfiguration.maximumIntervalRange)), 1)
    var valuesPerInterval = totalValues / numberOfIntervals

    // for safety always request more values in case or rounding issues, this will be a visual representation to the
    // user and we want to avoid empty spaces
    let remainderValues = totalValues % numberOfIntervals
    if remainderValues > 0 {
      valuesPerInterval += 1
    }

    numberOfIntervals = Int(ceil(Double(totalValues) / Double(valuesPerInterval)))
    let adjustedIntervalDuration = totalDuration / Double(numberOfIntervals)

    return (valuesPerInterval, adjustedIntervalDuration)
  }

  private func haveRecordingsAtCurrentPosition() -> Bool {
    let timeBegin = interactor.timelineProperties.player.playheadPosition.seconds
    let position = wavePosition(for: timeBegin)

    guard totalOfsamples - 1 >= position, audioWaves.containsAudioWave(withPosition: position) else {
      return false
    }
    return true
  }

  private func checkButtonState() {
    guard state == .idle else { return }

    if !alreadyRecordedAudio, audioProvider.audioBlock == nil {
      recordingButtonState = .start
    } else {
      recordingButtonState = haveRecordingsAtCurrentPosition() ? .replace : .resume
    }

    isRecordingEnabled = player.playheadPosition.seconds < (totalDurationSeconds - 0.2)
  }

  private func shouldEnablePlayButton() {
    isPlayingEnabled = audioWaves.count == 0 ? false : true
  }

  private func reachedEndDuration() {
    switch state {
    case .recording:
      state = .idle
      // we want to avoid an empty space when the user stop recording or reached the end, so wee need to request data if
      // exist for that time
      if let lastEndIntervalRequestedInSeconds {
        fetchAudioThumbnails(timeBegin: lastEndIntervalRequestedInSeconds, timeEnd: player.playheadPosition.seconds)
      }
    case .playing:
      state = .idle
      recordingButtonState = .resume
      isRecordingEnabled = false
    default: break
    }
  }

  // MARK: - Recording Management

  private func handleStateChange(from oldState: VoiceOverState, to newState: VoiceOverState) {
    guard oldState != newState else { return }

    switch oldState {
    case .recording:
      pauseRecording()
    case .playing:
      pausePlaying()
    default:
      break
    }

    switch newState {
    case .recording:
      startRecording()
    case .playing:
      startPlaying()
    case .idle:
      checkButtonState()
      shouldEnablePlayButton()
    default:
      break
    }
  }

  private func startRecording() {
    guard audioManager.status == .ready else {
      state = .error(Localization.errorEnvironmentRecording)
      return
    }

    DispatchQueue.main.async {
      self.recordingButtonState = .pause
      self.isPlayingEnabled = false
    }

    lastEndIntervalRequestedInSeconds = player.playheadPosition.seconds

    interactor.setBlockMuted(audioProvider.audioBlock, muted: true)

    audioProvider.resetOffsetPosition(for: player.playheadPosition.seconds,
                                      totalDuration: totalDurationSeconds)
    audioManager.start()
    interactor.play()

    // Start the timer for fetching thumbnails,
    // we give an delay in order to let receive date before the request
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.thumbnailTimer?.start()
    }
    alreadyRecordedAudio = true
  }

  private func pauseRecording() {
    audioManager.pause()
    interactor.pause()

    interactor.setBlockMuted(audioProvider.audioBlock, muted: false)

    // Pause the timer when recording is paused
    thumbnailTimer?.stop()

    // Fetch remaining thumbnails
    if let lastEndIntervalRequestedInSeconds {
      fetchAudioThumbnails(timeBegin: lastEndIntervalRequestedInSeconds, timeEnd: player.playheadPosition.seconds)
    }

    DispatchQueue.main.async {
      self.checkButtonState()
      self.shouldEnablePlayButton()
    }

    audioWaves.resetRecordedFlags()
  }

  private func startPlaying() {
    interactor.play()
    isRecordingEnabled = false
  }

  private func pausePlaying() {
    interactor.pause()
    checkButtonState()
  }

  private func setAudio(audioBufferData: AVAudioPCMBuffer) {
    do {
      try audioProvider.setAudio(audioBufferData: audioBufferData)
    } catch {}
  }

  // MARK: - Notifications

  private func configureNotifications() {
    didEnterBackgroundNotificationPublisher = NotificationCenter.default.publisher(
      for: UIApplication.didEnterBackgroundNotification,
      object: nil,
    )
    .sink { [weak self] _ in
      self?.pauseAnyActivity()
    }

    willResignActiveNotificationPublisher = NotificationCenter.default.publisher(
      for: UIApplication.willResignActiveNotification,
      object: nil,
    )
    .sink { [weak self] _ in
      self?.pauseAnyActivity()
    }
  }
}

// MARK: - VoiceOverViewModelProtocol

extension VoiceOverViewModel: VoiceOverViewModelProtocol {
  func toggleAction() async {
    switch state {
    case .idle, .playing, .error:
      let canRecord = await AudioRecordPermissionsManager.checkAudioRecordingPermission()
      if canRecord == .denied {
        isShowingPermissionsAlertForMicrophone = true
      } else {
        state = .recording
      }
    case .recording:
      state = .idle
    case .loading, .ended: break
    }
  }

  func togglePlay() {
    state = (state == .playing) ? .idle : .playing
  }

  func toggleExternalAudio() {
    isSoundMuted.toggle()
    interactor.setPageMuted(isSoundMuted)
  }

  func pauseAnyActivity() {
    state = .idle
  }

  func doneAction() {
    pauseAnyActivity()

    Task {
      do {
        cleanUp()

        // End the audio block and handle any errors
        try await audioProvider.endAudioBlock()

        // If no changes were made, just dismiss
        guard alreadyRecordedAudio else {
          self.state = .ended
          return
        }

        if let id = audioProvider.audioBlock {
          interactor.refreshThumbnail(id: id)
          interactor.select(id: id)
        }

        // Add an undo step and update the state
        self.interactor.addUndoStep()
        self.state = .ended
      } catch {
        self.state = .error(Localization.errorAudioEngineCreateFile)
      }
    }
  }

  func cancelAction() {
    Task {
      do {
        cleanUp()

        guard alreadyRecordedAudio else {
          if mode == .edit {
            // No recorded audio, restore the local file
            try await audioProvider.cancelChangesAudioBlock()
          }

          self.state = .ended
          return
        }

        if mode == .edit {
          try await audioProvider.cancelChangesAudioBlock()
          if let id = self.audioProvider.audioBlock {
            self.interactor.refreshThumbnail(id: id)
          }
        } else {
          // If it was a new voiceover, we need to delete the existed file in the engine
          if let id = self.audioProvider.audioBlock {
            self.interactor.delete(id: id)
          }
        }
        self.state = .ended
      } catch {
        self.state = .error(Localization.errorAudioEngineCreateFile)
      }
    }
  }
}

// MARK: - AudioRecordDelegate

extension VoiceOverViewModel: AudioRecordDelegate {
  func audioEngineDidEncounterError(_: AudioRecordManager, error: AudioRecordError) {
    if error == .failedSetup {
      state = .error(Localization.errorAudioHardwareSetup)
    }
  }

  func audioEngineDidReceiveBuffer(_: AudioRecordManager, buffer: AVAudioPCMBuffer, atTime _: AVAudioTime) {
    setAudio(audioBufferData: buffer)
  }

  func engineWasInterrupted(_: AudioRecordManager) {
    pauseAnyActivity()
  }

  func engineConfigurationHasChanged(_: AudioRecordManager) {
    pauseAnyActivity()
  }
}
