import AVFoundation
import IMGLYEngine
import SwiftUI
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI

/// Protocol for providing voice-over audio functionalities.
@MainActor
protocol VoiceOverAudioProvider {
  /// The audio block identifier.
  var audioBlock: Interactor.BlockID? { get }
  /// Initializes a new instance of `VoiceOverAudioProvider`.
  /// - Parameter interactor: The interactor used for managing audio blocks.
  init(interactor: AudioInteractor)
  /// Sets up the provider for a specific audio block.
  /// - Parameter audioBlock: The identifier of the audio block.
  /// - Throws: An error if the setup fails.
  func setup(for audioBlock: Interactor.BlockID) async throws
  /// Resets the offset position for the audio buffer.
  /// - Parameters:
  ///   - seconds: The offset time in seconds.
  ///   - totalDuration: The total duration of the audio, if available.
  func resetOffsetPosition(for seconds: Double, totalDuration: Double?)
  /// Sets the audio data on the buffer.
  /// - Parameter audioBufferData: The audio buffer data to set.
  /// - Throws: An error if setting the audio data fails.
  func setAudio(audioBufferData: AVAudioPCMBuffer) throws
  /// Loads audio thumbnails for a specific time range.
  /// - Parameters:
  ///   - timeBegin: The start time for the thumbnails.
  ///   - timeEnd: The end time for the thumbnails.
  ///   - numberOfSamples: The number of thumbnail samples to load.
  /// - Returns: An asynchronous stream of audio thumbnails.
  /// - Throws: An error if loading the thumbnails fails.
  func loadAudioThumbnails(timeBegin: Double, timeEnd: Double, numberOfSamples: Int) async throws
    -> AsyncThrowingStream<AudioThumbnail, Swift.Error>
  /// Ends the current audio block and optionally writes the data to a file.
  /// - Throws: An error if ending the audio block fails.
  func endAudioBlock() async throws -> Bool
  /// Ends the current audio block and restores last date if needed..
  /// - Throws: An error if ending the audio block fails.
  func cancelChangesAudioBlock() async throws
}

/// A provider for managing audio blocks and buffers.
@MainActor
final class AudioProvider {
  // MARK: - Constants

  private enum AudioMetrics {
    static let numberChannels = 2
    static let sampleRateValue = AudioRecordSettings.SampleRate.rate48000.value
    static let numberBytes = 4
    static let audioFileFormat = "wav"
    static let wavHeaderLength = 44
  }

  private enum Localization {
    static let missingAudioBlock = "Missing AudioBlock"
    static let missingBuffer = "Missing Buffer"
    static let sampleRateConversionRequired = """
    Sample rate conversion required but not implemented,
    it should be converted in the AudioRecord
    """
    static let errorCreatingFile = "Something happens while creating audio file"
  }

  // MARK: - Properties

  var audioBlock: Interactor.BlockID?

  private var interactor: AudioInteractor
  private var buffer: URL?
  private var currentSampleOffset: UInt = 0
  private var audioBlockTimeOffset: Double = 0
  private var fileURL: URL?
  private var audioBlockWasUpdated: Bool = false

  var currentBufferURL: URL? { buffer }

  // MARK: - Initializers

  required init(interactor: AudioInteractor) {
    self.interactor = interactor
    try? self.interactor.startAudioOutputDevice()
  }

  // MARK: - Methods

  /// Creates an audio block if it doesn't already exist.
  private func createAudioBlock() throws {
    if audioBlock == nil {
      audioBlock = try interactor.createAudioBlock()
    }
  }

  /// Creates an audio buffer for the current audio block.
  private func createBuffer() throws {
    guard let audioBlock else { throw Error(errorDescription: Localization.missingAudioBlock) }
    buffer = try interactor.createAudioBlockBuffer(for: audioBlock)
  }

  private func createAudioFileUrl() throws -> URL {
    do {
      return try FileManager.default
        .getUniqueCacheURL()
        .appendingPathExtension(AudioMetrics.audioFileFormat)
    } catch {
      throw Error(errorDescription: Localization.errorCreatingFile)
    }
  }

  /// Interleaves audio data for stereo output.
  private func interleaveAudioData(_ audioBufferData: AVAudioPCMBuffer) throws -> [Float] {
    guard let channelData = audioBufferData.floatChannelData else {
      print("Failed to retrieve float channel data from the audio buffer.")
      return []
    }

    let frameLength = Int(audioBufferData.frameLength)
    let channelCount = Int(audioBufferData.format.channelCount)
    let sampleRate = audioBufferData.format.sampleRate
    let audioFormat = audioBufferData.format

    guard sampleRate == AudioRecordSettings.preferredAudioSetting.sampleRate.value else {
      throw Error(errorDescription: Localization.sampleRateConversionRequired)
    }

    let isInterleaved = audioFormat.isInterleaved
    var interleaved = [Float]()
    interleaved.reserveCapacity(frameLength * AudioMetrics.numberChannels) // we always send stereo to the engine

    if isInterleaved, channelCount == 2 {
      // Audio is already interleaved and stereo
      if let bufferListPointer =
        audioBufferData.audioBufferList.pointee.mBuffers.mData?.assumingMemoryBound(to: Float.self) {
        interleaved.append(contentsOf: UnsafeBufferPointer(start: bufferListPointer, count: frameLength * 2))
      }
    } else {
      for i in 0 ..< frameLength {
        let left = channelData[0][i]
        let right = (channelCount == 2) ? channelData[1][i] : left // Use same data for both channels if mono
        interleaved.append(left)
        interleaved.append(right)
      }
    }

    return interleaved
  }
}

// MARK: - VoiceOverAudioProvider

extension AudioProvider: VoiceOverAudioProvider {
  private func secondsToSample(seconds: Double) -> UInt {
    let calculatedTime = Int(floor(seconds * AudioMetrics.sampleRateValue))
    return UInt(calculatedTime * AudioMetrics.numberChannels * AudioMetrics.numberBytes)
  }

  private func sampleToSeconds(sample: UInt) -> Double {
    let samplesPerChannel = sample / UInt(AudioMetrics.numberChannels * AudioMetrics.numberBytes)
    return Double(samplesPerChannel) / AudioMetrics.sampleRateValue
  }

  var recordedDuration: Double {
    sampleToSeconds(sample: currentSampleOffset)
  }

  func setup(for audioBlock: DesignBlockID) async throws {
    // read an existed data stored for that audioblock
    // create a new buffer
    // fill the buffer from the data
    self.audioBlock = audioBlock
    buffer = nil
    audioBlockTimeOffset = (try? interactor.getAudioBlockTimeOffset(for: audioBlock)) ?? 0
    currentSampleOffset = 0
    audioBlockWasUpdated = false
    fileURL = try interactor.getAudioBlockURL(for: audioBlock)
    if fileURL?.scheme == "buffer" {
      fileURL = nil
    }

    if fileURL != nil,
       let audioData = try await interactor.getAudioBlockFileData(for: audioBlock) {
      try createBuffer()
      if let buffer {
        try interactor.setAudioBlockBuffer(audioData: audioData, on: buffer, at: 0)
        try interactor.setAudioBlockBufferLength(url: buffer, length: UInt(audioData.count))
        currentSampleOffset = UInt(audioData.count)
      }
    }
  }

  func resetOffsetPosition(for seconds: Double, totalDuration: Double?) {
    _ = totalDuration
    do {
      let clampedSeconds = max(0, seconds)
      if buffer == nil {
        try createAudioBlock()
        try createBuffer()
        if let audioBlock {
          audioBlockTimeOffset = clampedSeconds
          try interactor.setAudioBlockTimeOffset(for: audioBlock, to: audioBlockTimeOffset)
        }
        if let buffer {
          try interactor.setAudioBlockBufferLength(url: buffer, length: 0)
        }
        currentSampleOffset = 0
      } else {
        let relativeSeconds = max(0, clampedSeconds - audioBlockTimeOffset)
        currentSampleOffset = secondsToSample(seconds: relativeSeconds)
      }
      if let audioBlock, let buffer {
        try interactor.setAudioBlockURL(for: audioBlock, to: buffer)
      }
    } catch {
      print("Failed to reset offset position:", error)
    }
  }

  func setAudio(audioBufferData: AVAudioPCMBuffer) throws {
    guard let buffer else { throw Error(errorDescription: Localization.missingBuffer) }

    let interleavedData = try interleaveAudioData(audioBufferData)
    let dataAudio = interleavedData.withUnsafeBufferPointer { Data(buffer: $0) }

    try interactor.setAudioBlockBuffer(audioData: dataAudio, on: buffer, at: currentSampleOffset)
    currentSampleOffset += UInt(dataAudio.count)
    try interactor.setAudioBlockBufferLength(url: buffer, length: currentSampleOffset)

    if !audioBlockWasUpdated {
      audioBlockWasUpdated = true
    }
  }

  func loadAudioThumbnails(timeBegin: Double,
                           timeEnd: Double,
                           numberOfSamples: Int) async throws -> AsyncThrowingStream<AudioThumbnail, Swift.Error> {
    guard let audioBlock else { throw Error(errorDescription: Localization.missingAudioBlock) }

    return try await interactor.generateAudioBlockThumbnails(audioBlock,
                                                             from: timeBegin,
                                                             until: timeEnd,
                                                             with: numberOfSamples)
  }

  func endAudioBlock() async throws -> Bool {
    // If there is no audio block and it has not been updated, return early
    // If there have been updates to the audio block, but the block is missing, throw an error
    guard let audioBlock else {
      if audioBlockWasUpdated {
        throw Error(errorDescription: Localization.missingAudioBlock)
      } else {
        return false
      }
    }

    // If the audio block has been updated, create a new audio file with the updated data.
    if audioBlockWasUpdated {
      // create the data from the audio
      // write the audio data to the new file
      // update the audio block to point to the new file URL
      guard let buffer else { throw Error(errorDescription: Localization.missingBuffer) }
      defer { try? destroyBufferIfNeeded() }
      do {
        try interactor.setAudioBlockURL(for: audioBlock, to: buffer)
        var audioData = try await interactor.createAudioBlockData(from: audioBlock)
        if audioData.count <= AudioMetrics.wavHeaderLength, currentSampleOffset > 0 {
          audioData = try createWAVDataFromBuffer(buffer, length: currentSampleOffset)
        }
        guard audioData.count > AudioMetrics.wavHeaderLength else {
          if let fileURL {
            try interactor.setAudioBlockURL(for: audioBlock, to: fileURL)
            return true
          }
          return false
        }

        let url = try createAudioFileUrl()
        try audioData.write(to: url, options: .atomic)
        try interactor.setAudioBlockURL(for: audioBlock, to: url)
        fileURL = url
        return true
      } catch {
        if let fileURL {
          try? interactor.setAudioBlockURL(for: audioBlock, to: fileURL)
        }
        throw error
      }
    } else if let fileURL {
      // If no updates were made, ensure the audio block URL points to the existing file
      try interactor.setAudioBlockURL(for: audioBlock, to: fileURL)
      try? destroyBufferIfNeeded()
      return true
    }
    try? destroyBufferIfNeeded()
    return false
  }

  func cancelChangesAudioBlock() async throws {
    guard let audioBlock, let fileURL else {
      try? destroyBufferIfNeeded()
      return
    }

    try interactor.setAudioBlockURL(for: audioBlock, to: fileURL)
    try? destroyBufferIfNeeded()
  }

  private func destroyBufferIfNeeded() throws {
    guard let buffer else { return }
    try interactor.destroyAudioBlockBuffer(url: buffer)
    self.buffer = nil
  }

  private func createWAVDataFromBuffer(_ buffer: URL, length: UInt) throws -> Data {
    let pcmData = try interactor.getAudioBlockBufferData(url: buffer, offset: 0, length: length)
    var wavData = Data(capacity: AudioMetrics.wavHeaderLength + pcmData.count)

    wavData.append(contentsOf: "RIFF".utf8)
    wavData.appendUInt32LE(UInt32(36 + pcmData.count))
    wavData.append(contentsOf: "WAVE".utf8)
    wavData.append(contentsOf: "fmt ".utf8)
    wavData.appendUInt32LE(16)
    wavData.appendUInt16LE(3) // IEEE float PCM
    wavData.appendUInt16LE(UInt16(AudioMetrics.numberChannels))
    wavData.appendUInt32LE(UInt32(AudioMetrics.sampleRateValue))
    wavData
      .appendUInt32LE(UInt32(AudioMetrics
          .sampleRateValue * Double(AudioMetrics.numberChannels * AudioMetrics.numberBytes)))
    wavData.appendUInt16LE(UInt16(AudioMetrics.numberChannels * AudioMetrics.numberBytes))
    wavData.appendUInt16LE(UInt16(AudioMetrics.numberBytes * 8))
    wavData.append(contentsOf: "data".utf8)
    wavData.appendUInt32LE(UInt32(pcmData.count))
    wavData.append(pcmData)

    return wavData
  }
}

private extension Data {
  mutating func appendUInt16LE(_ value: UInt16) {
    var littleEndian = value.littleEndian
    Swift.withUnsafeBytes(of: &littleEndian) { append(contentsOf: $0) }
  }

  mutating func appendUInt32LE(_ value: UInt32) {
    var littleEndian = value.littleEndian
    Swift.withUnsafeBytes(of: &littleEndian) { append(contentsOf: $0) }
  }
}
