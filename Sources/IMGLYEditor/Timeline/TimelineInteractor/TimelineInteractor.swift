import CoreMedia
import Foundation
import IMGLYEngine
import SwiftUI

/// The protocol that the `Timeline` expects.
@MainActor
protocol TimelineInteractor: ObservableObject {
  var timelineProperties: TimelineProperties { get }
  var isLoopingPlaybackEnabled: Bool { get }
  var isVoiceOverRecordModeActive: Bool { get }
  var isVoiceOverRecordModeRecording: Bool { get }
  var hasVoiceOverRecordModeRecordedAudio: Bool { get }
  var voiceOverRecordModeTarget: DesignBlockID? { get }

  func setTrim(clip: Clip, timeOffset: CMTime, trimOffset: CMTime, duration: CMTime)
  /// Commits preview offsets to the engine and mirrors them into `Clip.timeOffset` so
  /// the UI never has to mutate the authoritative value itself.
  func commitPreviewedOffsets(_ offsets: [DesignBlockID: CMTime])
  /// Commits a drag-and-drop to the engine. `siblingOffsets` supplies the preview
  /// positions for every sibling in the target track.
  func applyDrop(clip: Clip, target: DropTarget, siblingOffsets: [DesignBlockID: CMTime])
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
  func getTextContent(id: DesignBlockID) throws -> String
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
  func forceLoadAudioResource(for clip: Clip) async throws
  func play(seekToStartIfNeeded: Bool)
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

extension TimelineInteractor {
  func play() {
    play(seekToStartIfNeeded: true)
  }
}
