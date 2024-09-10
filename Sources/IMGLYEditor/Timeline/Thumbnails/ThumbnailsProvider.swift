import CoreMedia
import IMGLYCore
import IMGLYEngine
import SwiftUI

/// Asynchronously loads video thumbnail preview images.
@MainActor
class ThumbnailsProvider: ObservableObject {
  weak var interactor: (any TimelineInteractor)?

  @Published private(set) var availableWidth: Double = 0
  @Published private(set) var aspectRatio: Double = 1
  @Published private(set) var images = [CGImage?]()
  @Published private(set) var isLoading = false
  @Published private(set) var thumbHeight: Double = 44

  private var task: Task<Void, Never>?

  private let screenResolutionScaleFactor: CGFloat = UIScreen.main.scale

  private var previousFootageURLString: String?

  private var debounceTimer: Timer?

  init(interactor: any TimelineInteractor) {
    self.interactor = interactor
  }

  deinit {
    task?.cancel()
  }

  func cancel() {
    task?.cancel()
  }

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

    guard ![.audio, .voiceOver].contains(clip.clipType) else { return }

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
          try await interactor.generateThumbnails(
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
}
