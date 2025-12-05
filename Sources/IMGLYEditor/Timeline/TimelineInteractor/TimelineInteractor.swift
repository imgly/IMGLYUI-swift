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
  func refreshThumbnail(id: DesignBlockID)
  func startScrubbing(clip: Clip)
  func scrub(clip: Clip, time: CMTime)
  func stopScrubbing(clip: Clip)
  func select(id: DesignBlockID?)
  func deselect()
  func delete(id: DesignBlockID?)
  func addUndoStep()
  func getAspectRatio(clip: Clip) throws -> Double
  func generateImagesThumbnails(
    clip: Clip,
    thumbHeight: CGFloat,
    timeRange: ClosedRange<Double>,
    screenResolutionScaleFactor: CGFloat,
    numberOfFrames: Int,
  ) async throws -> AsyncThrowingStream<VideoThumbnail, Swift.Error>
  func generateAudioThumbnails(
    clip: Clip,
    timeRange: ClosedRange<Double>,
    numberOfSamples: Int,
  ) async throws -> AsyncThrowingStream<AudioThumbnail, Swift.Error>
  func play()
  func pause()
  func togglePlayback()
  func setPageMuted(_ muted: Bool)
  func setBlockMuted(_ id: DesignBlockID?, muted: Bool)
  func setPlayheadPosition(_ time: CMTime)
  func toggleIsLoopingPlaybackEnabled()
  func addAssetToBackgroundTrack()
  func addAudioAsset()
  func openVoiceOver(style: SheetStyle)
  func openCamera(_ assetSourceIDs: [MediaType: String])
}
