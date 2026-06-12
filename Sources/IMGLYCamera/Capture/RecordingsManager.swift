import CoreMedia
import SwiftUI

class RecordingsManager: ObservableObject {
  var maxTotalDuration: CMTime
  var allowExceedingMaxDuration: Bool

  @Published var currentlyRecordedClipDuration: CMTime?

  /// The captures collected so far. Holds photos and recorded video clips side-by-side.
  @Published private(set) var captures: [Capture] = []

  var recordedClipsTotalDuration: CMTime {
    captures.reduce(CMTime.zero) { partialResult, capture in
      partialResult + capture.duration
    }
  }

  var recordedClipsDurations: [CMTime] {
    captures.map(\.duration)
  }

  var hasRecordings: Bool {
    !captures.isEmpty
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
    allowExceedingMaxDuration: Bool,
  ) {
    self.maxTotalDuration = maxTotalDuration
    self.allowExceedingMaxDuration = allowExceedingMaxDuration
  }

  // MARK: - File management

  func add(_ capture: Capture) {
    captures.append(capture)
  }

  func deleteAll() throws {
    try delete(captures)
  }

  func deleteLastCapture() throws {
    guard let lastCapture = captures.last else {
      throw InternalCameraError(errorDescription: "Can’t delete because there are no captures.")
    }

    try delete([lastCapture])
    captures.removeLast()
  }

  func delete(_ captures: [Capture]) throws {
    let urls = captures.flatMap(\.fileURLs)
    for url in urls {
      try FileManager.default.removeItem(at: url)
    }
  }
}
