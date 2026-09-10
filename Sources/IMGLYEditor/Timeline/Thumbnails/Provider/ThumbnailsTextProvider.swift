import SwiftUI

/// Provider for text clip content.
@MainActor
class ThumbnailsTextProvider {
  @Published private(set) var text: String = ""
  @Published var isLoading = false

  weak var interactor: (any TimelineInteractor)?

  init(interactor: any TimelineInteractor) {
    self.interactor = interactor
  }
}

// MARK: - ThumbnailsProvider

extension ThumbnailsTextProvider: ThumbnailsProvider {
  func loadThumbnails(clip: Clip, availableWidth _: Double, thumbHeight _: Double) {
    text = (try? interactor?.getTextContent(id: clip.id)) ?? ""
  }

  func cancel() {}
}
