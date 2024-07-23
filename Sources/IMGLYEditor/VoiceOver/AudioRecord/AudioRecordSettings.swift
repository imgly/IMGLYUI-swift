import AVFoundation

/// A configuration structure for audio recording settings.
struct AudioRecordSettings {
  static let preferredAudioSetting = AudioRecordSettings(channels: Channels.stereo,
                                                         sampleRate: SampleRate.rate48000,
                                                         format: .pcmFormatFloat32)

  /// Enum to represent the possible sample rates for audio recording.
  enum SampleRate {
    case rate44100
    case rate48000
    case other(Double)

    var value: Double {
      switch self {
      case .rate44100: return 44100
      case .rate48000: return 48000
      case let .other(value): return value
      }
    }
  }

  /// Enum to represent the number of audio channels.
  enum Channels {
    case mono
    case stereo

    var value: UInt32 {
      switch self {
      case .mono: return 1
      case .stereo: return 2
      }
    }
  }

  var channels: Channels
  var sampleRate: SampleRate
  var format: AVAudioCommonFormat

  /// Initializes a new audio recording configuration with specified settings.
  /// - Parameters:
  ///   - channels: The number of channels, either `.mono` or `.stereo`.
  ///   - sampleRate: The sample rate; can be one of the standard rates or a custom rate using `.other`.
  ///   - format: The common format for the audio.
  init(channels: Channels, sampleRate: SampleRate, format: AVAudioCommonFormat) {
    self.channels = channels
    self.sampleRate = sampleRate
    self.format = format
  }
}
