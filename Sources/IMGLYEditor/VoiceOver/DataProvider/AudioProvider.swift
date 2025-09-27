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
  func endAudioBlock() async throws
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
  private var fileURL: URL?
  private var audioBlockWasUpdated: Bool = false

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

  /// Sets the buffer size based on the total duration.
  private func setBufferWithSize(of totalDuration: Double) {
    guard let buffer else { return }

    let frames = Int(ceil(totalDuration * AudioMetrics.sampleRateValue))
    let bufferSizeLength = UInt(frames * AudioMetrics.numberChannels * AudioMetrics.numberBytes)
    do {
      try interactor.setAudioBlockBufferLength(url: buffer, length: bufferSizeLength)
    } catch {
      print("Failed to set buffer length:", error)
    }
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

  func setup(for audioBlock: DesignBlockID) async throws {
    // read an existed data stored for that audioblock
    // create a new buffer
    // fill the buffer from the data
    self.audioBlock = audioBlock

    if let fileURL = try interactor.getAudioBlockURL(for: audioBlock),
       let audioData = try await interactor.getAudioBlockFileData(for: audioBlock) {
      try createBuffer()
      if let buffer {
        try interactor.setAudioBlockBuffer(audioData: audioData, on: buffer, at: 0)
      }
      self.fileURL = fileURL
    }
  }

  func resetOffsetPosition(for seconds: Double, totalDuration: Double?) {
    do {
      if buffer == nil {
        try createAudioBlock()
        try createBuffer()
        if let totalDuration {
          setBufferWithSize(of: totalDuration)
        }
      }
      currentSampleOffset = secondsToSample(seconds: seconds)
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

  func endAudioBlock() async throws {
    // If there is no audio block and it has not been updated, return early
    // If there have been updates to the audio block, but the block is missing, throw an error
    guard let audioBlock else {
      if audioBlockWasUpdated {
        throw Error(errorDescription: Localization.missingAudioBlock)
      } else {
        return
      }
    }

    // If the audio block has been updated, create a new audio file with the updated data.
    if audioBlockWasUpdated {
      // create the data from the audio
      // write the audio data to the new file
      // update the audio block to point to the new file URL
      let url = try createAudioFileUrl()
      let audioData = try await interactor.createAudioBlockData(from: audioBlock)
      try audioData.write(to: url, options: .atomic)
      try interactor.setAudioBlockURL(for: audioBlock, to: url)

    } else if let fileURL {
      // If no updates were made, ensure the audio block URL points to the existing file
      try interactor.setAudioBlockURL(for: audioBlock, to: fileURL)
    }
  }

  func cancelChangesAudioBlock() async throws {
    guard let audioBlock, let fileURL else {
      return
    }

    try interactor.setAudioBlockURL(for: audioBlock, to: fileURL)
  }
}
