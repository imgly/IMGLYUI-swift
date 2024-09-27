import CoreMedia
import IMGLYCore
import IMGLYEngine
import SwiftUI

/// Provider for loading image thumbnails
@MainActor
class ThumbnailsImageProvider {
  // MARK: - Properties

  let screenResolutionScaleFactor: CGFloat = UIScreen.main.scale

  @Published var isLoading = false
  @Published var availableWidth: Double = 0
  @Published var thumbHeight: Double = 44
  @Published var thumbWidth: Double = 2

  @Published private(set) var images = [CGImage?]()

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

extension ThumbnailsImageProvider: ThumbnailsProvider {
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
        // Ensure thumbWidth is at least 4px otherwise is just a blur thumbnail
        let thumbWidth = max(round(thumbHeight * aspectRatio), 4)
        let numberOfFrames = Int((availableWidth / thumbWidth).rounded(.awayFromZero))
        self.thumbWidth = thumbWidth

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
