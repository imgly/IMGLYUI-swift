import CoreMedia
import IMGLYCore
import IMGLYEngine
import SwiftUI

/// Provider for loading image thumbnails
@MainActor
class ThumbnailsImageProvider {
  // MARK: - Properties

  let screenResolutionScaleFactor: CGFloat = UIScreen.main.scale

  @Published internal var isLoading = false
  @Published internal var thumbHeight: Double = 44
  @Published internal var availableWidth: Double = 0
  @Published internal var aspectRatio: Double = 1

  @Published private(set) var images = [CGImage?]()

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

extension ThumbnailsImageProvider: ThumbnailsProvider {
  func loadThumbnails(clip: Clip, availableWidth: Double, thumbHeight: Double, debounce: TimeInterval) {
    debounceTimer?.invalidate()
    debounceTimer = Timer.scheduledTimer(withTimeInterval: debounce, repeats: false, block: { [weak self] _ in
      Task { @MainActor [weak self] in
        self?.loadThumbnails(clip: clip, availableWidth: availableWidth, thumbHeight: thumbHeight)
      }
    })
  }

  func loadThumbnails(clip: Clip, availableWidth: Double, thumbHeight: Double) {
    guard availableWidth > 0 else { return }

    previousFootageURLString = clip.footageURLString
    self.thumbHeight = thumbHeight

    guard let interactor else {
      assertionFailure("Missing interactor")
      return
    }

    guard let duration = clip.duration else { return }
    let timeRange = 0 ... duration.seconds

    guard let aspectRatio = try? interactor.getAspectRatio(clip: clip) else { return }

    var images = [CGImage?]()

    cancel()
    isLoading = true

    task = Task { [weak self] in
      guard let self else { return }
      do {
        self.aspectRatio = aspectRatio
        let thumbWidth = round(thumbHeight * aspectRatio)
        let numberOfFrames = Int((availableWidth / thumbWidth).rounded(.awayFromZero))
        guard numberOfFrames > 0 else { return }

        for try await thumb in
          try await interactor.generateImagesThumbnails(
            clip: clip,
            thumbHeight: thumbHeight,
            timeRange: timeRange,
            screenResolutionScaleFactor: screenResolutionScaleFactor,
            numberOfFrames: numberOfFrames
          ) {
          images.append(thumb.image)
        }

        // Rendering was cancelled or failed if the image count doesn’t match,
        // so we skip showing the incomplete image set.
        guard images.count == numberOfFrames else { return }

        self.images.removeAll()
        self.images = images
        self.availableWidth = availableWidth
        isLoading = false
      } catch {}
    }
  }

  func cancel() {
    task?.cancel()
  }
}
