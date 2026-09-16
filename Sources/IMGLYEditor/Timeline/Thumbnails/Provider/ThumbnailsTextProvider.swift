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
    let newText = (try? interactor?.getTextContent(id: clip.id)) ?? ""
    // Republishing an unchanged value would invalidate every text clip view on
    // each history step — costly with hundreds of captions.
    if text != newText {
      text = newText
    }
  }

  func cancel() {}
}
