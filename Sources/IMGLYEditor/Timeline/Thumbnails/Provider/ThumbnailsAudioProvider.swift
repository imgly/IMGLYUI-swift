import CoreMedia
import Foundation

/// Provider for loading audio thumbnails.
@MainActor
class ThumbnailsAudioProvider {
  // MARK: - Properties

  @Published internal var isLoading = false
  @Published internal var thumbHeight: Double = 44
  @Published internal var availableWidth: Double = 0

  @Published private(set) var audioWaves = [Float]()

  internal weak var interactor: (any TimelineInteractor)?
  internal var task: Task<Void, Never>?
  internal var previousFootageURLString: String?
  internal var debounceTimer: Timer?

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
  func loadThumbnails(clip: Clip, availableWidth: Double, thumbHeight: Double, debounce: TimeInterval) {
    debounceTimer?.invalidate()
    debounceTimer = Timer.scheduledTimer(withTimeInterval: debounce, repeats: false, block: { [weak self] _ in
      Task { @MainActor [weak self] in
        self?.loadThumbnails(clip: clip, availableWidth: availableWidth, thumbHeight: thumbHeight)
      }
    })
  }

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
