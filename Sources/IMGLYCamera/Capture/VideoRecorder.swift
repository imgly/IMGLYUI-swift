import AVFoundation
import Foundation

class VideoRecorder: @unchecked Sendable {
  private var assetWriter: AVAssetWriter?

  private var assetWriterVideoInput: AVAssetWriterInput?
  private var assetWriterAudioInput: AVAssetWriterInput?

  private var videoTransform: CGAffineTransform
  private var videoSettings: [String: Any]
  private var audioSettings: [String: Any]

  private(set) var isRecording = false

  private var startTimestamp = CMTime.zero
  private var currentTimestamp = CMTime.zero

  var recordedDuration: CMTime? {
    guard isRecording else { return nil }
    return currentTimestamp - startTimestamp
  }

  init(
    audioSettings: [String: Any],
    videoSettings: [String: Any],
    videoTransform: CGAffineTransform
  ) {
    self.audioSettings = audioSettings
    self.videoSettings = videoSettings
    self.videoTransform = videoTransform
  }

  func startRecording(to url: URL, fileType: AVFileType) {
    guard let assetWriter = try? AVAssetWriter(url: url, fileType: fileType) else {
      // Recording errors should be handled here.
      return
    }

    let assetWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
    assetWriterAudioInput.expectsMediaDataInRealTime = true
    assetWriter.add(assetWriterAudioInput)

    let assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
    assetWriterVideoInput.expectsMediaDataInRealTime = true
    assetWriterVideoInput.transform = videoTransform
    assetWriter.add(assetWriterVideoInput)

    self.assetWriter = assetWriter
    self.assetWriterAudioInput = assetWriterAudioInput
    self.assetWriterVideoInput = assetWriterVideoInput

    isRecording = true
  }

  func stopRecording() async throws -> (URL, CMTime) {
    guard let assetWriter,
          assetWriter.status == .writing else {
      throw (
        InternalCameraError(
          // swiftlint:disable:next line_length
          errorDescription: "Stopping failed. AssetWriter: \(assetWriter.debugDescription), isRecording: \(isRecording)",
        ),
      )
    }

    self.assetWriter = nil
    await assetWriter.finishWriting()

    let recordedDuration = recordedDuration ?? .zero
    isRecording = false

    return (assetWriter.outputURL, recordedDuration)
  }

  func recordVideoSample(sampleBuffer: CMSampleBuffer) {
    guard isRecording,
          let assetWriter else {
      return
    }
    // Could use a check for writing errors in assetWriter.status == .failed
    if assetWriter.status == .unknown {
      assetWriter.startWriting()
      let startTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
      assetWriter.startSession(atSourceTime: startTimestamp)
      self.startTimestamp = startTimestamp
      currentTimestamp = startTimestamp
    }
    if assetWriter.status == .writing,
       let input = assetWriterVideoInput,
       input.isReadyForMoreMediaData {
      input.append(sampleBuffer)
      currentTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
    }
  }

  func recordAudioSample(sampleBuffer: CMSampleBuffer) {
    guard isRecording,
          let assetWriter,
          assetWriter.status == .writing,
          let input = assetWriterAudioInput,
          input.isReadyForMoreMediaData else {
      return
    }
    input.append(sampleBuffer)
  }
}
