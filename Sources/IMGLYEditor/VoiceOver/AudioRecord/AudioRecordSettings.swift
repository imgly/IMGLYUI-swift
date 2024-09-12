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
      case .rate44100: 44100
      case .rate48000: 48000
      case let .other(value): value
      }
    }
  }

  /// Enum to represent the number of audio channels.
  enum Channels {
    case mono
    case stereo

    var value: UInt32 {
      switch self {
      case .mono: 1
      case .stereo: 2
      }
    }
  }

  var channels: Channels
  var sampleRate: SampleRate
  var format: AVAudioCommonFormat
}
