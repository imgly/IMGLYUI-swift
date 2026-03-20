import CoreMedia
import Foundation
import QuartzCore

/// Provider for loading audio thumbnails.
@MainActor
class ThumbnailsAudioProvider {
  private enum Loading {
    static let maxAttempts = 3
    static let retryDelayNanoseconds: UInt64 = 150_000_000
    static let liveBufferRefreshInterval: CFTimeInterval = 0.4
  }

  // MARK: - Properties

  @Published var isLoading = false
  @Published var thumbHeight: Double = 44
  @Published var availableWidth: Double = 0

  @Published private(set) var audioWaves = [Float]()

  /// The trimOffset for which the current audioWaves were loaded.
  /// Used to keep waves at their loaded position until new samples arrive after trimming.
  @Published private(set) var loadedTrimOffset: CMTime = .zero

  weak var interactor: (any TimelineInteractor)?
  var task: Task<Void, Never>?
  var previousFootageURLString: String?
  private var lastLiveBufferRefreshAt: CFTimeInterval = 0

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
  func loadThumbnails(clip: Clip, availableWidth: Double, thumbHeight: Double) {
    guard availableWidth > 0, let duration = clip.duration else { return }

    guard let interactor else {
      assertionFailure("Missing interactor")
      return
    }

    /// cancel any previous request
    cancel()

    let isLiveBufferResource = clip.footageURLString?.hasPrefix("buffer://") == true
    let now = CACurrentMediaTime()
    if isLiveBufferResource,
       !audioWaves.isEmpty,
       now - lastLiveBufferRefreshAt < Loading.liveBufferRefreshInterval {
      return
    }

    guard clip.footageURLString != nil else {
      audioWaves = []
      loadedTrimOffset = clip.trimOffset
      isLoading = false
      return
    }

    previousFootageURLString = clip.footageURLString
    self.thumbHeight = thumbHeight

    let trimOffsetSeconds = clip.trimOffset.seconds
    let timeRange = trimOffsetSeconds ... (trimOffsetSeconds + duration.seconds)

    // Calculate sample count to match HStack layout: N bars + (N-1) gaps = 2N - 1 pixels
    let barWidth = 1.0
    let barGap = 1.0
    let numberOfSamples = max(1, Int(round((availableWidth + barGap) / (barWidth + barGap))))

    task = Task { [weak self] in
      guard let self else { return }
      isLoading = true

      defer { isLoading = false }

      for attempt in 0 ..< Loading.maxAttempts {
        do {
          var receivedSamples = false
          for try await thumb in
            try await interactor.generateAudioThumbnails(
              clip: clip,
              timeRange: timeRange,
              numberOfSamples: numberOfSamples,
            ) {
            guard !Task.isCancelled else { return }
            audioWaves = thumb.samples
            loadedTrimOffset = clip.trimOffset
            receivedSamples = receivedSamples || !thumb.samples.isEmpty
          }

          if receivedSamples {
            self.availableWidth = availableWidth
            if isLiveBufferResource {
              lastLiveBufferRefreshAt = CACurrentMediaTime()
            }
            return
          }
        } catch {
          debugPrint("Failed to load audio thumbnails:", error)
        }

        guard !isLiveBufferResource else { break }
        guard attempt < Loading.maxAttempts - 1 else { break }

        do {
          try await interactor.forceLoadAudioResource(for: clip)
        } catch {
          debugPrint("Failed to force-load audio resource:", error)
        }

        try? await Task.sleep(nanoseconds: Loading.retryDelayNanoseconds)
      }
    }
  }

  func cancel() {
    task?.cancel()
  }
}
