@preconcurrency import Combine
import CoreMedia
import Foundation
import IMGLYEngine
@_spi(Internal) import IMGLYCore
import SwiftUI

class AnyTimelineInteractor: TimelineInteractor {
  var timelineProperties: TimelineProperties { interactor.timelineProperties }
  var isLoopingPlaybackEnabled: Bool { interactor.isLoopingPlaybackEnabled }

  func setTrim(clip: Clip, timeOffset: CMTime, trimOffset: CMTime, duration: CMTime) {
    interactor.setTrim(clip: clip, timeOffset: timeOffset, trimOffset: trimOffset, duration: duration)
  }

  func splitSelectedClipAtPlayheadPosition() {
    interactor.splitSelectedClipAtPlayheadPosition()
  }

  func reorderBackgroundTrack(clip: Clip, toIndex index: Int) {
    interactor.reorderBackgroundTrack(clip: clip, toIndex: index)
  }

  func refreshTimeline() {
    interactor.refreshTimeline()
  }

  func refreshThumbnails() {
    interactor.refreshThumbnails()
  }

  func refreshThumbnail(id: DesignBlockID) {
    interactor.refreshThumbnail(id: id)
  }

  func startScrubbing(clip: Clip) {
    interactor.startScrubbing(clip: clip)
  }

  func scrub(clip: Clip, time: CMTime) {
    interactor.scrub(clip: clip, time: time)
  }

  func stopScrubbing(clip: Clip) {
    interactor.stopScrubbing(clip: clip)
  }

  func select(id: DesignBlockID?) {
    interactor.select(id: id)
  }

  func deselect() {
    interactor.deselect()
  }

  func delete(id: DesignBlockID?) {
    interactor.delete(id: id)
  }

  func addUndoStep() {
    interactor.addUndoStep()
  }

  func getAspectRatio(clip: Clip) throws -> Double {
    try interactor.getAspectRatio(clip: clip)
  }

  func generateImagesThumbnails(
    clip: Clip,
    thumbHeight: CGFloat,
    timeRange: ClosedRange<Double>,
    screenResolutionScaleFactor: CGFloat,
    numberOfFrames: Int,
  ) async throws -> AsyncThrowingStream<VideoThumbnail, Swift.Error> {
    try await interactor.generateImagesThumbnails(
      clip: clip,
      thumbHeight: thumbHeight,
      timeRange: timeRange,
      screenResolutionScaleFactor: screenResolutionScaleFactor,
      numberOfFrames: numberOfFrames,
    )
  }

  func generateAudioThumbnails(clip: Clip,
                               timeRange: ClosedRange<Double>,
                               numberOfSamples: Int) async throws -> AsyncThrowingStream<
    IMGLYEngine.AudioThumbnail,
    Swift.Error
  > {
    try await interactor.generateAudioThumbnails(
      clip: clip,
      timeRange: timeRange,
      numberOfSamples: numberOfSamples,
    )
  }

  func play() {
    interactor.play()
  }

  func pause() {
    interactor.pause()
  }

  func setPageMuted(_ muted: Bool) {
    interactor.setPageMuted(muted)
  }

  func setBlockMuted(_ id: IMGLYEngine.DesignBlockID?, muted: Bool) {
    interactor.setBlockMuted(id, muted: muted)
  }

  func togglePlayback() {
    interactor.togglePlayback()
  }

  func setPlayheadPosition(_ time: CMTime) {
    interactor.setPlayheadPosition(time)
  }

  func toggleIsLoopingPlaybackEnabled() {
    interactor.toggleIsLoopingPlaybackEnabled()
  }

  func addAssetToBackgroundTrack() {
    interactor.addAssetToBackgroundTrack()
  }

  func addAudioAsset() {
    interactor.addAudioAsset()
  }

  func openVoiceOver(style: SheetStyle) {
    interactor.openVoiceOver(style: style)
  }

  func openCamera(_ assetSourceIDs: [MediaType: String]) {
    interactor.openCamera(assetSourceIDs)
  }

  private let interactor: any TimelineInteractor

  init(erasing interactor: some TimelineInteractor) {
    self.interactor = interactor

    objectWillChange = interactor
      .objectWillChange
      .map { _ in }
      .eraseToAnyPublisher()
  }

  nonisolated let objectWillChange: AnyPublisher<Void, Never>
}
