import CoreMedia
import Foundation

/// Provider for loading audio thumbnails.
@MainActor
class ThumbnailsAudioProvider {
  // MARK: - Properties

  @Published var isLoading = false
  @Published var thumbHeight: Double = 44
  @Published var availableWidth: Double = 0

  @Published private(set) var audioWaves = [Float]()

  /// The trimOffset for which the current audioWaves were loaded.
  /// Used to keep waves at their loaded position until new samples arrive after trimming.
  @Published private(set) var loadedTrimOffset: CMTime = .zero

  weak var interactor: (any TimelineInteractor)?
  var task: Task<Void, Never>?
  var previousFootageURLString: String?

  // MARK: - Initializers

  init(interactor: any TimelineInteractor) {
    self.interactor = interactor
  }

  deinit {
    task?.cancel()
  }
}

// MARK: - ThumbnailsProvider

extension ThumbnailsAudioProvider: ThumbnailsProvider {
  func loadThumbnails(clip: Clip, availableWidth: Double, thumbHeight: Double) {
    guard availableWidth > 0, let duration = clip.duration else { return }

    guard let interactor else {
      assertionFailure("Missing interactor")
      return
    }

    /// cancel any previous request
    cancel()

    previousFootageURLString = clip.footageURLString
    self.thumbHeight = thumbHeight

    let trimOffsetSeconds = clip.trimOffset.seconds
    let timeRange = trimOffsetSeconds ... (trimOffsetSeconds + duration.seconds)

    // Calculate sample count to match HStack layout: N bars + (N-1) gaps = 2N - 1 pixels
    let barWidth = 1.0
    let barGap = 1.0
    let numberOfSamples = max(1, Int(round((availableWidth + barGap) / (barWidth + barGap))))

    task = Task { [weak self] in
      guard let self else { return }
      isLoading = true

      do {
        for try await thumb in
          try await interactor.generateAudioThumbnails(
            clip: clip,
            timeRange: timeRange,
            numberOfSamples: numberOfSamples,
          ) {
          audioWaves = thumb.samples
          loadedTrimOffset = clip.trimOffset
        }

        self.availableWidth = availableWidth
        isLoading = false
      } catch {}
    }
  }

  func cancel() {
    task?.cancel()
  }
}
