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

  func getAspectRatio(clip: Clip) throws -> Double {
    try interactor.getAspectRatio(clip: clip)
  }

  func generateThumbnails(
    clip: Clip,
    thumbHeight: CGFloat,
    timeRange: ClosedRange<Double>,
    screenResolutionScaleFactor: CGFloat,
    numberOfFrames: Int
  ) async throws -> AsyncThrowingStream<VideoThumbnail, Swift.Error> {
    try await interactor.generateThumbnails(
      clip: clip,
      thumbHeight: thumbHeight,
      timeRange: timeRange,
      screenResolutionScaleFactor: screenResolutionScaleFactor,
      numberOfFrames: numberOfFrames
    )
  }

  func play() {
    interactor.play()
  }

  func pause() {
    interactor.pause()
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

  func absoluteStartTime(clip: Clip) -> CMTime {
    interactor.absoluteStartTime(clip: clip)
  }

  func addAssetToBackgroundTrack() {
    interactor.addAssetToBackgroundTrack()
  }

  func addAudioAsset() {
    interactor.addAudioAsset()
  }

  func openCamera() {
    interactor.openCamera()
  }

  func openImagePicker() {
    interactor.openImagePicker()
  }

  private let interactor: any TimelineInteractor

  init(erasing interactor: some TimelineInteractor) {
    self.interactor = interactor

    objectWillChange = interactor
      .objectWillChange
      .map { _ in }
      .eraseToAnyPublisher()
  }

  let objectWillChange: AnyPublisher<Void, Never>
}
