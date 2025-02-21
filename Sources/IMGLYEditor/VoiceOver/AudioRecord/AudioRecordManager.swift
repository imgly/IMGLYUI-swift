import AVFoundation
import Combine
@_spi(Internal) import IMGLYCore

/// Enum representing errors that can occur during audio recording.
enum AudioRecordError: Swift.Error {
  case failedSetup
  case failedBuffer
  case noInputChannel
}

/// Enum representing current status of the recorder
enum AudioRecordStatus {
  case notInitialized
  case ready
}

/// Enum representing current status of the recorder
enum AudioRecordMode {
  case play
  case playAndRecord
}

/// Delegate protocol for handling audio recording events.
@MainActor
protocol AudioRecordDelegate: AnyObject {
  func audioEngineDidEncounterError(_ engine: AudioRecordManager, error: AudioRecordError)
  func audioEngineDidReceiveBuffer(_ engine: AudioRecordManager, buffer: AVAudioPCMBuffer, atTime: AVAudioTime)
  func engineWasInterrupted(_ engine: AudioRecordManager)
  func engineConfigurationHasChanged(_ engine: AudioRecordManager)
}

/// Protocol for providing audio recording functionality.
@MainActor
protocol AudioRecordManagerProvider {
  var status: AudioRecordStatus { get }
  var delegate: AudioRecordDelegate? { get set }

  func start()
  func pause()
  func stop()
}

/// Manager class for handling audio recording.
@MainActor
final class AudioRecordManager {
  // MARK: - Properties

  private var audioEngine: AVAudioEngine
  private let inputBus: AVAudioNodeBus = 0
  private let bufferSize: AVAudioFrameCount = 1024
  private let resampler = AVAudioMixerNode()

  private var desiredAudioNumberOfChannels: UInt32
  private var desiredAudioFormat: AVAudioCommonFormat
  private var desiredAudioSampleRate: Double

  private(set) var status: AudioRecordStatus = .notInitialized

  weak var delegate: AudioRecordDelegate?

  // MARK: - Initializers

  init(format: AVAudioCommonFormat = AudioRecordSettings.preferredAudioSetting.format,
       sampleRate: Double = AudioRecordSettings.preferredAudioSetting.sampleRate.value,
       numberChannels: UInt32 = AudioRecordSettings.preferredAudioSetting.channels.value,
       delegate: AudioRecordDelegate? = nil) {
    self.delegate = delegate

    desiredAudioNumberOfChannels = numberChannels
    desiredAudioFormat = format
    desiredAudioSampleRate = sampleRate

    audioEngine = AVAudioEngine()
    setup()
  }

  // MARK: - Private Methods

  private func setup() {
    AVAudioSession.push()

    configurePreferredAudioSettings()
    configureNotifications()

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      self?.configureAudioSession()
    }
  }

  /// Configures the audio session for recording.
  private nonisolated func configureAudioSession() {
    Task {
      let audioSession = AVAudioSession.sharedInstance()
      do {
        try audioSession.setCategory(
          .playAndRecord,
          options: [.defaultToSpeaker, .allowAirPlay, .allowBluetooth, .allowBluetoothA2DP]
        )
        try audioSession.setActive(true)
        await MainActor.run {
          self.configureAudioEngine()
          self.status = .ready
        }
      } catch {
        await MainActor.run {
          print(error)
          delegate?.audioEngineDidEncounterError(self, error: .failedSetup)
        }
      }
    }
  }

  /// Configures preferred audio settings.
  private func configurePreferredAudioSettings() {
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setPreferredSampleRate(desiredAudioSampleRate)
    } catch {
      print("Not able to set preferred sample rate")
    }
    do {
      try audioSession.setPreferredInputNumberOfChannels(Int(desiredAudioNumberOfChannels))
    } catch {
      print("Not able to set preferred number of input channels")
    }
  }

  /// Configures the audio engine for recording.
  private func configureAudioEngine() {
    let inputNode = audioEngine.inputNode
    let inputFormat = inputNode.inputFormat(forBus: inputBus)

    do {
      try inputNode.setVoiceProcessingEnabled(true)
    } catch {
      print("Could not enable voice processing \(error)")
    }

    guard let desiredFormat = AVAudioFormat(commonFormat: desiredAudioFormat,
                                            sampleRate: desiredAudioSampleRate,
                                            channels: desiredAudioNumberOfChannels,
                                            interleaved: false) else {
      delegate?.audioEngineDidEncounterError(self, error: .failedSetup)
      return
    }
    audioEngine.attach(resampler)

    let output = audioEngine.outputNode
    let mainMixer = audioEngine.mainMixerNode

    audioEngine.connect(mainMixer, to: output, format: inputFormat)
    audioEngine.connect(inputNode, to: resampler, format: desiredFormat)

    resampler.installTap(onBus: 0, bufferSize: bufferSize, format: desiredFormat) { [weak self] buffer, when in
      guard let self else { return }
      delegate?.audioEngineDidReceiveBuffer(self, buffer: buffer, atTime: when)
    }

    audioEngine.prepare()
  }

  /// Configures notifications for audio session events.
  private func configureNotifications() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(handleInterruption(_:)),
                                           name: AVAudioSession.interruptionNotification,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(handleMediaServicesReset(_:)),
                                           name: AVAudioSession.mediaServicesWereResetNotification,
                                           object: nil)
  }

  /// Handles audio session interruptions.
  @objc private func handleInterruption(_ notification: Notification) {
    guard let info = notification.userInfo,
          let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

    // we just want the init of an interruption, in case it stop it should be the user to start again the process
    if type == .began {
      pause()
      delegate?.engineWasInterrupted(self)
    }
  }

  // if we've received this notification, the media server has been reset
  // re-wire all the connections and start the engine
  @objc private func handleMediaServicesReset(_: Notification) {
    configurePreferredAudioSettings()
    configureAudioSession()

    delegate?.engineConfigurationHasChanged(self)
  }

  /// Starts the audio engine for recording.
  private func startRecording() {
    do {
      try audioEngine.start()
    } catch {
      delegate?.audioEngineDidEncounterError(self, error: .failedBuffer)
    }
  }
}

// MARK: - AudioEngineProvider

extension AudioRecordManager: AudioRecordManagerProvider {
  func start() {
    guard !audioEngine.isRunning else { return }

    guard audioEngine.inputNode.inputFormat(forBus: inputBus).channelCount > 0 else {
      delegate?.audioEngineDidEncounterError(self, error: .noInputChannel)
      return
    }

    startRecording()
  }

  func pause() {
    audioEngine.pause()
  }

  func stop() {
    audioEngine.inputNode.removeTap(onBus: inputBus)
    audioEngine.stop()
    do {
      try AVAudioSession.pop()
    } catch {
      print("Couldn't restore the audio session state. Did you pop it multiple times?")
    }
  }
}
