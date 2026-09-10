import CoreMedia
@_spi(Internal) import IMGLYCore
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

  /// Find the track that contains the given clip.
  func findTrack(containing clip: Clip) -> Track? {
    if backgroundTrack.clips.contains(where: { $0.id == clip.id }) {
      return backgroundTrack
    }
    return tracks.first { track in
      track.clips.contains { $0.id == clip.id }
    }
  }

  /// Returns the previous and next clips adjacent to the given clip within the same track, sorted by timeOffset.
  func neighborClips(of clip: Clip, in track: Track) -> (previous: Clip?, next: Clip?) {
    let sorted = track.clips.sorted { $0.timeOffset < $1.timeOffset }
    guard let index = sorted.firstIndex(where: { $0.id == clip.id }) else {
      return (nil, nil)
    }
    let previous = index > 0 ? sorted[index - 1] : nil
    let next = index < sorted.count - 1 ? sorted[index + 1] : nil
    return (previous, next)
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

    // Include foreground clip edges as snap points
    for clip in foregroundClips() {
      let start = clip.timeOffset
      if !snapDetents.contains(start) {
        snapDetents.append(start)
      }
      if let duration = clip.duration {
        let end = start + duration
        if !snapDetents.contains(end) {
          snapDetents.append(end)
        }
      }
    }

    self.snapDetents = snapDetents
  }
}
