import Foundation
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEngine

extension Interactor: AudioInteractor {
  /// Retrieves the engine instance or throws an error if it's missing.
  private var _engine: Engine {
    get throws {
      guard let engine else { throw Error(errorDescription: "Missing engine") }
      return engine
    }
  }

  func startAudioOutputDevice() throws {
    try _engine.editor.startAudioOutputDevice()
  }

  func createAudioBlock() throws -> DesignBlockID {
    guard let pageID = timelineProperties.currentPage else {
      throw Error(errorDescription: "Theres no current page")
    }

    let audioBlock = try _engine.block.create(.audio)
    try _engine.block.setKind(audioBlock, kind: BlockKindKey.voiceover.rawValue)
    try _engine.block.setLooping(audioBlock, looping: false)
    try _engine.block.appendChild(to: pageID, child: audioBlock)
    try _engine.block.setAlwaysOnTop(audioBlock, enabled: true)

    return audioBlock
  }

  func createAudioBlockBuffer(for _: DesignBlockID) throws -> URL {
    try _engine.editor.createBuffer()
  }

  func createAudioBlockData(from audioBlock: DesignBlockID) async throws -> Blob {
    for try await event in try await _engine.block.exportAudio(
      audioBlock,
      mimeType: .wav,
      options: .init(skipEncoding: true),
    ) {
      if case let .finished(audio: data) = event {
        return data
      }
    }
    return Blob()
  }

  func getAudioBlockFileData(for audioBlock: DesignBlockID) async throws -> Blob? {
    if let url = try getAudioBlockURL(for: audioBlock) {
      let (data, _) = try await URLSession.shared.data(from: url)
      return data.subdata(in: 44 ..< data.count) // Skip the first 44 header bytes
    }
    return nil
  }

  func getAudioBlockURL(for audioBlock: DesignBlockID) throws -> URL? {
    if let fileURI: String = try? _engine.block.get(audioBlock, property: .key(.audioFileURI)) {
      return URL(string: fileURI)
    }
    return nil
  }

  func getAudioBlockTimeOffset(for audioBlock: DesignBlockID) throws -> Double {
    try _engine.block.getTimeOffset(audioBlock)
  }

  func setAudioBlockURL(for audioBlock: DesignBlockID, to url: URL) throws {
    try _engine.block.set(audioBlock, property: .key(.audioFileURI), value: url)
  }

  func setAudioBlockTimeOffset(for audioBlock: DesignBlockID, to offset: Double) throws {
    try _engine.block.setTimeOffset(audioBlock, offset: offset)
  }

  func setAudioBlockBuffer(audioData: Data, on buffer: URL, at offset: UInt) throws {
    try _engine.editor.setBufferData(url: buffer, offset: offset, data: audioData)
  }

  func setAudioBlockBufferLength(url: URL, length: UInt) throws {
    try _engine.editor.setBufferLength(url: url, length: length)
  }

  func getAudioBlockBufferData(url: URL, offset: UInt, length: UInt) throws -> Data {
    try _engine.editor.getBufferData(url: url, offset: offset, length: length)
  }

  func destroyAudioBlockBuffer(url: URL) throws {
    try _engine.editor.destroyBuffer(url: url)
  }

  func generateAudioBlockThumbnails(
    _ audioBlock: DesignBlockID,
    from timeBegin: Double,
    until timeEnd: Double,
    with numberOfSamples: Int = 5,
  ) async throws -> AsyncThrowingStream<IMGLYEngine.AudioThumbnail, Swift.Error> {
    guard timeBegin < timeEnd else { throw Error(errorDescription: "Invalid time range") }

    let timeRange = timeBegin ... timeEnd
    return try _engine.block.generateAudioThumbnailSequence(
      audioBlock,
      samplesPerChunk: numberOfSamples,
      timeRange: timeRange,
      numberOfSamples: numberOfSamples,
      numberOfChannels: 1,
    )
  }
}
