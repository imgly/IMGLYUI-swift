import AVFoundation
@testable import IMGLYCamera
import XCTest

final class VideoRecorderOrientationTests: XCTestCase {
  func testRecordedFilesCarryUprightOrientationAndSnapshotLayout() async throws {
    let size = CGSize(width: 240, height: 320)
    for orientation in CameraOrientation.allCases {
      let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
      defer { try? FileManager.default.removeItem(at: url) }
      let rect = CGRect(x: 0, y: 0, width: 1080, height: 960)
      let recorder = VideoRecorder(
        audioSettings: [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 44100, AVNumberOfChannelsKey: 1],
        videoSettings: [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: 240, AVVideoHeightKey: 320],
        orientation: orientation,
        rect: rect,
      )
      recorder.startRecording(to: url, fileType: .mov)
      for index in 0 ..< 4 {
        recorder.recordVideoSample(sampleBuffer: try sample(at: CMTime(value: Int64(index), timescale: 30)))
        try await Task.sleep(for: .milliseconds(30))
      }
      let (recordedURL, _) = try await recorder.stopRecording()
      let asset = AVURLAsset(url: recordedURL)
      let tracks = try await asset.loadTracks(withMediaType: .video)
      let track = try XCTUnwrap(tracks.first)
      let transform = try await track.load(.preferredTransform)
      let naturalSize = try await track.load(.naturalSize)
      XCTAssertEqual(naturalSize, size)
      XCTAssertEqual(transform, orientation.captureTransform(size: size))
      XCTAssertEqual(recorder.rect, orientation.captureRect(rect))

      let generator = AVAssetImageGenerator(asset: asset)
      generator.appliesPreferredTrackTransform = true
      let image = try await generator.image(at: .zero).image
      XCTAssertEqual(image.width, orientation.isLandscape ? 320 : 240)
      XCTAssertEqual(image.height, orientation.isLandscape ? 240 : 320)
    }
  }

  private func sample(at time: CMTime) throws -> CMSampleBuffer {
    var pixelBuffer: CVPixelBuffer?
    XCTAssertEqual(CVPixelBufferCreate(kCFAllocatorDefault, 240, 320, kCVPixelFormatType_32BGRA,
                                       nil, &pixelBuffer), kCVReturnSuccess)
    let pixels = try XCTUnwrap(pixelBuffer)
    CVPixelBufferLockBaseAddress(pixels, [])
    if let base = CVPixelBufferGetBaseAddress(pixels) {
      memset(base, 128, CVPixelBufferGetBytesPerRow(pixels) * CVPixelBufferGetHeight(pixels))
    }
    CVPixelBufferUnlockBaseAddress(pixels, [])
    var format: CMVideoFormatDescription?
    XCTAssertEqual(CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                                imageBuffer: pixels, formatDescriptionOut: &format),
                   noErr)
    var timing = CMSampleTimingInfo(duration: CMTime(value: 1, timescale: 30),
                                    presentationTimeStamp: time, decodeTimeStamp: .invalid)
    var buffer: CMSampleBuffer?
    XCTAssertEqual(CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
                                                            imageBuffer: pixels,
                                                            formatDescription: try XCTUnwrap(format),
                                                            sampleTiming: &timing, sampleBufferOut: &buffer), noErr)
    return try XCTUnwrap(buffer)
  }
}
