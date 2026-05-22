import CoreMedia
import IMGLYEngine
import SwiftUI

struct TimelineScrollTargetRequest: Equatable {
  let id: DesignBlockID
  private let token = UUID()
}

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

  /// A transient clip target used when the timeline should scroll without changing the visible selection state.
  @Published var scrollTargetRequest: TimelineScrollTargetRequest?

  /// Video duration constraints for the current timeline.
  @Published var videoDurationConstraints = VideoDurationConstraints()

  /// Drives preview rendering across tracks; engine state is written only on release.
  @Published var dragDropState: DragDropState = .idle

  /// Foreground `Track.id` → window-space frame, published by each `TrackView` via
  /// `TrackFramesPreferenceKey`. Drag & drop maps pointer Y to a target track.
  @Published var trackFrames: [UUID: CGRect] = [:]

  /// Horizontal scroll view's `contentOffset.x` in points. Drag & drop reads it so
  /// the drop slot stays anchored to the finger as auto-scroll moves the timeline.
  @Published var horizontalScrollOffsetPoints: CGFloat = 0

  /// `applyDrop`'s cross-track and new-track branches refresh synchronously; the
  /// engine then fires async events that would refresh again and flash an empty
  /// frame. Set `true` after a sync refresh, cleared by the next dirty event.
  /// Drags are user-gated and serialized (touch must release before the next can start),
  /// so a Bool is sufficient — no counter needed. Intentionally non-`@Published` because
  /// it's transient bookkeeping, not UI state.
  var suppressNextDirtyRefresh: Bool = false

  /// Live delta applied to the background track's trailing edge during a trim drag
  /// on a background clip, so UI anchored there (most visibly "+ Add Clip") tracks
  /// the preview instead of jumping on commit.
  @Published var backgroundTrackTrimDelta: CMTime = .zero

  // MARK: - Methods

  func resetClips() {
    dataSource.reset()
    selectedClip = nil
  }

  func requestScroll(to clipID: DesignBlockID) {
    scrollTargetRequest = .init(id: clipID)
  }

  func consumeScrollRequest(_ request: TimelineScrollTargetRequest) {
    if scrollTargetRequest == request {
      scrollTargetRequest = nil
    }
  }
}
