import Foundation

/// Protocol to provide thumbnail loading functionality
@MainActor
protocol ThumbnailsProvider: ObservableObject {
  /// Loads thumbnails for a given clip with a debounce period.
  /// - Parameters:
  ///   - clip: The clip for which to load thumbnails.
  ///   - availableWidth: The available width for the thumbnails.
  ///   - thumbHeight: The height of the thumbnails.
  ///   - debounce: The debounce interval in seconds.
  func loadThumbnails(clip: Clip, availableWidth: Double, thumbHeight: Double, debounce: TimeInterval)
  /// Loads thumbnails for a given clip.
  /// - Parameters:
  ///   - clip: The clip for which to load thumbnails.
  ///   - availableWidth: The available width for the thumbnails.
  ///   - thumbHeight: The height of the thumbnails.
  func loadThumbnails(clip: Clip, availableWidth: Double, thumbHeight: Double)
  /// Cancels the current thumbnail loading task.
  func cancel()
}
