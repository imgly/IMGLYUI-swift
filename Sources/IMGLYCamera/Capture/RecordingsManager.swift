import CoreMedia
import SwiftUI

class RecordingsManager: ObservableObject {
  var maxTotalDuration: CMTime
  var allowExceedingMaxDuration: Bool

  @Published var currentlyRecordedClipDuration: CMTime?

  /// The recorded clips, containing one (single camera) or two (dual camera) `URL`s.
  @Published private(set) var clips: [Recording] = []

  var recordedClipsTotalDuration: CMTime {
    clips.reduce(CMTime.zero) { partialResult, video in
      partialResult + video.duration
    }
  }

  var recordedClipsDurations: [CMTime] {
    clips.map(\.duration)
  }

  var hasRecordings: Bool {
    !clips.isEmpty
  }

  var hasReachedMaxDuration: Bool {
    !allowExceedingMaxDuration && recordedClipsTotalDuration >= maxTotalDuration
  }

  var remainingRecordingDuration: CMTime {
    allowExceedingMaxDuration
      ? .positiveInfinity
      : maxTotalDuration - recordedClipsTotalDuration
  }

  // MARK: -

  init(
    maxTotalDuration: CMTime,
    allowExceedingMaxDuration: Bool
  ) {
    self.maxTotalDuration = maxTotalDuration
    self.allowExceedingMaxDuration = allowExceedingMaxDuration
  }

  // MARK: - File management

  func add(_ clip: Recording) {
    clips.append(clip)
  }

  func deleteAll() throws {
    try delete(recordings: clips)
  }

  func deleteLastRecording() throws {
    guard let lastRecording = clips.last else {
      throw InternalCameraError(errorDescription: "Can’t delete because there are no clips.")
    }

    try delete(recordings: [lastRecording])
    clips.removeLast()
  }

  func delete(recordings: [Recording]) throws {
    let urls = recordings.flatMap { $0.videos.map(\.url) }
    for url in urls {
      try FileManager.default.removeItem(at: url)
    }
  }
}
