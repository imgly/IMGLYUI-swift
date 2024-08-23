import CoreMedia
import IMGLYEngine
import SwiftUI

@MainActor
class TimelineProperties: ObservableObject {
  // MARK: - Timeline

  /// The `TimelineDataSource` caches the engine’s state for the timeline.
  let dataSource = TimelineDataSource()

  /// The `Player` manages the playback state and playhead position.
  let player = Player()

  /// The `Timeline` manages the timeline zoom level and dimensions.
  var timeline: Timeline?

  /// Timeline appearance and behavior settings.
  let configuration = TimelineConfiguration()

  var currentPage: DesignBlockID?

  /// The background track contains the main video and image blocks.
  var backgroundTrack: DesignBlockID?

  /// Used for previewing video while trimming. Added and removed on the fly.
  var scrubbingPreviewLayer: DesignBlockID?

  /// Tracks whether the user is currently scrubbing (while trimming) a video.
  var isScrubbing = false

  /// Keeps track of the order of blocks to refresh the timeline if the order has changed.
  var blockOrder = [DesignBlockID]()

  /// Manages and updates all thumbnails in the timeline.
  let thumbnailsManager = ThumbnailsManager()

  /// The clip that is currently selected in the timeline.
  @Published var selectedClip: Clip?

  // MARK: - Methods

  func resetClips() {
    dataSource.reset()
    selectedClip = nil
  }
}
