import IMGLYEngine
import SwiftUI
@_spi(Internal) import IMGLYCore

/// Manages all thumbnails for the whole timeline.
@MainActor
class ThumbnailsManager {
  weak var interactor: (any TimelineInteractor)?

  private(set) var providers = [DesignBlockID: any ThumbnailsProvider]()

  private func createProvider(for clip: Clip) throws {
    guard let interactor else { throw Error(errorDescription: "Missing Interactor") }

    switch clip.clipType {
    case .audio, .voiceOver:
      let provider = ThumbnailsAudioProvider(interactor: interactor)
      providers[clip.id] = provider
    default:
      let provider = ThumbnailsImageProvider(interactor: interactor)
      providers[clip.id] = provider
    }
  }

  func getProvider(clip: Clip) throws -> any ThumbnailsProvider {
    if let provider = providers[clip.id] {
      return provider
    } else {
      try createProvider(for: clip)
      guard let provider = providers[clip.id] else {
        throw Error(errorDescription: "Thumbnail Provider could not be found or created.")
      }
      return provider
    }
  }

  func destroyProvider(id: DesignBlockID) {
    guard let provider = providers[id] else { return }
    provider.cancel()
    providers[id] = nil
  }

  func destroyProviders() {
    providers.forEach { $0.value.cancel() }
    providers.removeAll()
  }

  func refreshThumbnails(for clip: Clip, width: Double, height: Double) throws {
    let provider = try getProvider(clip: clip)
    provider.loadThumbnails(clip: clip, availableWidth: width, thumbHeight: height)
  }
}
