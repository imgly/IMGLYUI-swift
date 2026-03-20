import AVFoundation
import IMGLYEngine

/// Protocol that defines the operations for handling audio interactions.
@MainActor
protocol AudioInteractor {
  /// Creates an audio block.
  /// - Returns: The identifier of the newly created audio block.
  func createAudioBlock() throws -> DesignBlockID
  /// Creates an audio buffer for a specified audio block.
  /// - Parameter audioBlock: The identifier of the audio block.
  /// - Returns: The URL of the created audio buffer.
  func createAudioBlockBuffer(for audioBlock: DesignBlockID) throws -> URL
  /// Creates an audio block data blob.
  /// - Parameter audioBlock: The identifier of the audio block.
  /// - Returns: The audio data blob.
  func createAudioBlockData(from audioBlock: DesignBlockID) async throws -> Blob
  /// Retrieves the audio file data for a specified audio block.
  /// - Parameter audioBlock: The identifier of the audio block.
  /// - Returns: The audio file data.
  func getAudioBlockFileData(for audioBlock: DesignBlockID) async throws -> Data?
  /// Retrieves the audio file URL for a specified audio block.
  /// - Parameter audioBlock: The identifier of the audio block.
  /// - Returns: The audio file URL.
  func getAudioBlockURL(for audioBlock: DesignBlockID) throws -> URL?
  /// Retrieves the playback time offset for a specified audio block in timeline seconds.
  /// - Parameter audioBlock: The identifier of the audio block.
  /// - Returns: The playback time offset in seconds.
  func getAudioBlockTimeOffset(for audioBlock: DesignBlockID) throws -> Double
  /// Workaround to have the audio output device started before any recording
  func startAudioOutputDevice() throws
  /// Sets the URL for an audio block.
  /// - Parameters:
  ///   - audioBlock: The identifier of the audio block.
  ///   - url: The URL to set.
  func setAudioBlockURL(for audioBlock: DesignBlockID, to url: URL) throws
  /// Sets the playback time offset for a specified audio block in timeline seconds.
  /// - Parameters:
  ///   - audioBlock: The identifier of the audio block.
  ///   - offset: The new playback time offset in seconds.
  func setAudioBlockTimeOffset(for audioBlock: DesignBlockID, to offset: Double) throws
  /// Sets audio data on a specified buffer at a given offset.
  /// - Parameters:
  ///   - audioData: The audio data to set.
  ///   - buffer: The URL of the buffer.
  ///   - offset: The offset at which to set the audio data.
  func setAudioBlockBuffer(audioData: Data, on buffer: URL, at offset: UInt) throws
  /// Sets the length of a specified buffer.
  /// - Parameters:
  ///   - url: The URL of the buffer.
  ///   - length: The length to set for the buffer.
  func setAudioBlockBufferLength(url: URL, length: UInt) throws
  /// Reads audio data from a specified buffer.
  /// - Parameters:
  ///   - url: The URL of the buffer.
  ///   - offset: The byte offset at which to start reading.
  ///   - length: The number of bytes to read.
  /// - Returns: The buffer data.
  func getAudioBlockBufferData(url: URL, offset: UInt, length: UInt) throws -> Data
  /// Destroys a specified buffer.
  /// - Parameter url: The URL of the buffer.
  func destroyAudioBlockBuffer(url: URL) throws
  /// Generates an audio thumbnail for a specified audio block within a time range.
  /// - Parameters:
  ///   - audioBlock: The identifier of the audio block.
  ///   - timeBegin: The beginning of the time range.
  ///   - timeEnd: The end of the time range.
  ///   - numberOfSamples: The number of samples to generate.
  /// - Returns: An asynchronous stream of audio thumbnails.
  func generateAudioBlockThumbnails(
    _ audioBlock: DesignBlockID,
    from timeBegin: Double,
    until timeEnd: Double,
    with numberOfSamples: Int,
  ) async throws -> AsyncThrowingStream<IMGLYEngine.AudioThumbnail, Swift.Error>
}
