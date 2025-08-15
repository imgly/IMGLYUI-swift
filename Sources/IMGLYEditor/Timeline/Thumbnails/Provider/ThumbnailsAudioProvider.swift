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

    task = Task { [weak self] in
      guard let self else { return }
      isLoading = true

      do {
        let timeRange = 0 ... duration.seconds
        let numberOfSamples = Int(availableWidth / (1.0 + 1.0))

        for try await thumb in
          try await interactor.generateAudioThumbnails(
            clip: clip,
            timeRange: timeRange,
            numberOfSamples: numberOfSamples
          ) {
          audioWaves = thumb.samples
        }

        self.availableWidth = availableWidth
        isLoading = false
      } catch {
        print(error)
      }
    }
  }

  func cancel() {
    task?.cancel()
  }
}
