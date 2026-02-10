import CoreMedia
import IMGLYCore
import IMGLYEngine
import SwiftUI

/// Provider for loading image thumbnails
@MainActor

class ThumbnailsImageProvider {
  // MARK: - Properties

  private enum Metrics {
    // Minimum width for thumbnail to avoid blurring; should be at least 4px.
    static let thumbMinWidth: CGFloat = 4.0
  }

  let screenResolutionScaleFactor: CGFloat = UIScreen.main.scale

  @Published var isLoading = false
  @Published var availableWidth: Double = 0
  @Published var thumbHeight: Double = 44
  @Published var thumbWidth: Double = Metrics.thumbMinWidth
  @Published private(set) var clipType: ClipType = .invalid
  @Published private(set) var aspectRatio: Double = 1.0

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
  /// Determines if this clip type is "still" content (single frame, not video)
  private static func isStillContent(_ clipType: ClipType) -> Bool {
    switch clipType {
    case .image, .sticker, .shape:
      true
    default:
      false
    }
  }

  func loadThumbnails(clip: Clip, availableWidth: Double, thumbHeight: Double) {
    guard availableWidth > 0 else { return }

    previousFootageURLString = clip.footageURLString
    self.thumbHeight = thumbHeight
    clipType = clip.clipType

    guard let interactor else {
      assertionFailure("Missing interactor")
      return
    }

    guard let duration = clip.duration,
          let aspectRatio = try? interactor.getAspectRatio(clip: clip) else { return }

    cancel()
    isLoading = true

    let timeRange = 0 ... duration.seconds
    task = Task { [weak self] in
      await self?.generateThumbnails(
        clip: clip,
        interactor: interactor,
        availableWidth: availableWidth,
        thumbHeight: thumbHeight,
        aspectRatio: aspectRatio,
        timeRange: timeRange,
      )
    }
  }

  private func generateThumbnails(
    clip: Clip,
    interactor: any TimelineInteractor,
    availableWidth: Double,
    thumbHeight: Double,
    aspectRatio: Double,
    timeRange: ClosedRange<Double>,
  ) async {
    do {
      self.aspectRatio = aspectRatio
      let thumbWidth = max(round(thumbHeight * aspectRatio), Metrics.thumbMinWidth)
      self.thumbWidth = thumbWidth

      // For still content (images, stickers, shapes), only generate 1 thumbnail
      // For video content, calculate based on available width
      let numberOfFrames = Self.isStillContent(clip.clipType)
        ? 1
        : Int((availableWidth / thumbWidth).rounded(.awayFromZero))
      guard numberOfFrames > 0 else { return }

      var images = [CGImage?]()
      for try await thumb in
        try await interactor.generateImagesThumbnails(
          clip: clip,
          thumbHeight: thumbHeight,
          timeRange: timeRange,
          screenResolutionScaleFactor: screenResolutionScaleFactor,
          numberOfFrames: numberOfFrames,
        ) {
        images.append(thumb.image)
      }

      // Rendering was cancelled or failed if the image count doesn't match,
      // so we skip showing the incomplete image set.
      guard images.count == numberOfFrames else { return }

      self.images = images
      self.availableWidth = availableWidth
      isLoading = false
    } catch {}
  }

  func cancel() {
    task?.cancel()
  }
}
