import Combine
import SwiftUI

/// Wrapper class for any ThumbnailsProvider conforming object.
/// This class allows for type-erased handling of different ThumbnailsProvider implementations.
final class AnyThumbnailsProvider {
  // Publishes changes to subscribers
  let objectWillChange: AnyPublisher<Void, Never>
  let provider: any ThumbnailsProvider

  init(erasing provider: some ThumbnailsProvider) {
    self.provider = provider

    objectWillChange = provider
      .objectWillChange
      .map { _ in }
      .eraseToAnyPublisher()
  }
}

// MARK: - ThumbnailsProvider

extension AnyThumbnailsProvider: ThumbnailsProvider {
  func loadThumbnails(clip: Clip, availableWidth: Double, thumbHeight: Double) {
    provider.loadThumbnails(clip: clip, availableWidth: availableWidth, thumbHeight: thumbHeight)
  }

  func cancel() {
    provider.cancel()
  }
}
