import CoreMedia
import IMGLYEngine
import SwiftUI

/// The data model for the Timeline visualization.
final class TimelineDataSource: ObservableObject {
  /// The `Track`s that contain `Clip`s
  @Published var tracks = [Track]()
  @Published var backgroundTrack = Track()

  /// Timecodes in the video track that clips in other tracks should snap to when moved or trimmed.
  @Published var snapDetents = [CMTime]()

  /// Find clip by `id`.
  func findClip(id: DesignBlockID) -> Clip? {
    var allTracks = tracks
    allTracks.append(backgroundTrack)

    for track in allTracks {
      for clip in track.clips where clip.id == id {
        return clip
      }
    }
    return nil
  }

  /// Find the clip by `id`, including fills, shapes, blurs, and applied effect `id`s.
  func findClip(containing id: DesignBlockID) -> Clip? {
    var allTracks = tracks
    allTracks.append(backgroundTrack)

    for track in allTracks {
      for clip in track.clips where clip.id == id {
        return clip
      }
      for clip in track.clips where clip.fillID == id {
        return clip
      }
      for clip in track.clips where clip.shapeID == id {
        return clip
      }
      for clip in track.clips where clip.blurID == id {
        return clip
      }
      for clip in track.clips where clip.effectIDs.contains(id) {
        return clip
      }
    }
    return nil
  }

  func allClips() -> [Clip] {
    var clips = foregroundClips()
    clips.append(contentsOf: backgroundTrack.clips)
    return clips
  }

  func foregroundClips() -> [Clip] {
    var foregroundClips = [Clip]()
    foregroundClips = tracks.flatMap(\.clips)

    return foregroundClips
  }

  func reset() {
    tracks.removeAll()
    backgroundTrack.clips.removeAll()
  }

  func updateSnapDetents() {
    // Update snapping detents
    var absoluteTimeOffset = CMTime.zero
    var snapDetents = [CMTime]()

    // Snap to the timeline start
    snapDetents.append(.zero)

    for clip in backgroundTrack.clips {
      guard let duration = clip.duration else { continue }
      snapDetents.append(duration + absoluteTimeOffset)
      // swiftlint:disable:next shorthand_operator
      absoluteTimeOffset = absoluteTimeOffset + duration
    }

    self.snapDetents = snapDetents
  }
}
