import CoreMedia
import Foundation
import IMGLYEngine
import SwiftUI

/// The protocol that the `Timeline` expects.
@MainActor
protocol TimelineInteractor: ObservableObject {
  var timelineProperties: TimelineProperties { get }
  var isLoopingPlaybackEnabled: Bool { get }

  func setTrim(clip: Clip, timeOffset: CMTime, trimOffset: CMTime, duration: CMTime)
  func splitSelectedClipAtPlayheadPosition()
  func reorderBackgroundTrack(clip: Clip, toIndex index: Int)
  func refreshTimeline()
  func refreshThumbnails()
  func startScrubbing(clip: Clip)
  func scrub(clip: Clip, time: CMTime)
  func stopScrubbing(clip: Clip)
  func select(id: DesignBlockID?)
  func deselect()
  func getAspectRatio(clip: Clip) throws -> Double
  func generateThumbnails(
    clip: Clip,
    thumbHeight: CGFloat,
    timeRange: ClosedRange<Double>,
    screenResolutionScaleFactor: CGFloat,
    numberOfFrames: Int
  ) async throws -> AsyncThrowingStream<VideoThumbnail, Swift.Error>
  func play()
  func pause()
  func togglePlayback()
  func setPlayheadPosition(_ time: CMTime)
  func toggleIsLoopingPlaybackEnabled()
  func absoluteStartTime(clip: Clip) -> CMTime
  func addAssetToBackgroundTrack()
  func addAudioAsset()
  func openCamera()
  func openImagePicker()
}
