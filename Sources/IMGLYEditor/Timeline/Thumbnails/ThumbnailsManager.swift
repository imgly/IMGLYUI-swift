import IMGLYEngine
import SwiftUI
@_spi(Internal) import IMGLYCore

/// Manages all thumbnails for the whole timeline.
@MainActor
class ThumbnailsManager {
  weak var interactor: (any TimelineInteractor)?

  private(set) var providers = [DesignBlockID: ThumbnailsProvider]()

  func getProvider(id: DesignBlockID) throws -> ThumbnailsProvider {
    if let provider = providers[id] {
      return provider
    } else {
      try createProvider(for: id)
      guard let provider = providers[id] else {
        throw Error(errorDescription: "Thumbnail Provider could not be found or created.")
      }
      return provider
    }
  }

  func refreshThumbnails(for clip: Clip, width: Double, height: Double) throws {
    let provider = try getProvider(id: clip.id)
    provider.loadThumbnails(clip: clip, availableWidth: width, thumbHeight: height)
  }

  func refreshThumbnailsDebounced(for clip: Clip, width: Double, height: Double) throws {
    let provider = try getProvider(id: clip.id)
    provider.loadThumbnails(clip: clip, availableWidth: width, thumbHeight: height, debounce: 0.1)
  }

  func destroyProvider(id: DesignBlockID) {
    guard let provider = providers[id] else { return }
    provider.cancel()
    providers[id] = nil
  }

  private func createProvider(for id: DesignBlockID) throws {
    guard let interactor else { throw Error(errorDescription: "Missing Interactor") }
    let provider = ThumbnailsProvider(interactor: interactor)
    providers[id] = provider
  }
}
