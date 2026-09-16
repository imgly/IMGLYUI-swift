import CoreMedia
@_spi(Internal) import IMGLYCore
import IMGLYEngine
import SwiftUI

/// The data model for the Timeline visualization.
@MainActor
final class TimelineDataSource: ObservableObject {
  /// The `Track`s that contain `Clip`s
  @Published var tracks = [Track]()
  @Published var backgroundTrack = Track()

  /// The topmost caption lane — a stable instance (mirrors `backgroundTrack`);
  /// refreshes only mutate its `clips`/`engineTrackID`.
  @Published var captionTrack = Track()

  /// Whether the caption lane has clips. Republished because `Track.clips` is nested
  /// `@Published` and won't tick this object's `objectWillChange` on its own.
  @Published var hasCaptionClips = false

  /// Timecodes in the video track that clips in other tracks should snap to when moved or trimmed.
  @Published var snapDetents = [CMTime]()

  /// Lazily built lookup maps so `findClip` stays O(1) during engine event
  /// bursts (e.g. styling hundreds of captions); `nil` means stale.
  /// `byID` matches `Clip.id` only — callers rely on `nil` for fill/shape/blur/
  /// effect IDs — while `byContained` also maps those owned block IDs.
  private var clipLookup: (byID: [DesignBlockID: Clip], byContained: [DesignBlockID: Clip])?

  init() {
    captionTrack.$clips
      .map { !$0.isEmpty }
      .removeDuplicates()
      .assign(to: &$hasCaptionClips)
  }

  /// Drops the lookup maps; they are rebuilt on the next `findClip` call. Must
  /// be called after any change to track membership or to a clip's
  /// fill/shape/blur/effect IDs.
  func invalidateClipLookup() {
    clipLookup = nil
  }

  private func buildClipLookupIfNeeded() -> (byID: [DesignBlockID: Clip], byContained: [DesignBlockID: Clip]) {
    if let clipLookup {
      return clipLookup
    }

    var allTracks = tracks
    allTracks.append(backgroundTrack)
    allTracks.append(captionTrack)

    var byID = [DesignBlockID: Clip]()
    var byContained = [DesignBlockID: Clip]()
    for track in allTracks {
      for clip in track.clips {
        byID[clip.id] = clip
        var containedIDs = [clip.id]
        containedIDs.append(contentsOf: [clip.fillID, clip.shapeID, clip.blurID].compactMap(\.self))
        containedIDs.append(contentsOf: clip.effectIDs)
        for id in containedIDs where byContained[id] == nil {
          byContained[id] = clip
        }
      }
    }

    let lookup = (byID: byID, byContained: byContained)
    clipLookup = lookup
    return lookup
  }

  /// Find clip by `id`.
  func findClip(id: DesignBlockID) -> Clip? {
    buildClipLookupIfNeeded().byID[id]
  }

  /// Find the clip by `id`, including fills, shapes, blurs, and applied effect `id`s.
  func findClip(containing id: DesignBlockID) -> Clip? {
    buildClipLookupIfNeeded().byContained[id]
  }

  func allClips() -> [Clip] {
    var clips = foregroundClips()
    clips.append(contentsOf: backgroundTrack.clips)
    clips.append(contentsOf: captionTrack.clips)
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
    if captionTrack.clips.contains(where: { $0.id == clip.id }) {
      return captionTrack
    }
    return tracks.first { track in
      track.clips.contains { $0.id == clip.id }
    }
  }

  /// Returns the previous and next clips adjacent to the given clip within the same track, ordered by `timeOffset`.
  func neighborClips(of clip: Clip, in track: Track) -> (previous: Clip?, next: Clip?) {
    let clips = track.clips
    guard let clipIndex = clips.firstIndex(where: { $0.id == clip.id }) else {
      return (nil, nil)
    }
    // Single pass instead of sorting the whole track on every drag/trim frame — caption
    // lanes can hold hundreds of clips. Ordering by `(timeOffset, index)` breaks ties by
    // array position, exactly like the stable sort this replaces.
    let anchorOffset = clips[clipIndex].timeOffset
    var previousIndex: Int?
    var nextIndex: Int?
    for index in clips.indices where index != clipIndex {
      let offset = clips[index].timeOffset
      if (offset, index) < (anchorOffset, clipIndex) {
        if let previousIndex, (clips[previousIndex].timeOffset, previousIndex) >= (offset, index) {
          continue
        }
        previousIndex = index
      } else {
        if let nextIndex, (clips[nextIndex].timeOffset, nextIndex) <= (offset, index) {
          continue
        }
        nextIndex = index
      }
    }
    return (previousIndex.map { clips[$0] }, nextIndex.map { clips[$0] })
  }

  func reset() {
    tracks.removeAll()
    backgroundTrack.clips.removeAll()
    captionTrack.clips.removeAll()
    captionTrack.engineTrackID = nil
    invalidateClipLookup()
  }

  func updateSnapDetents() {
    // Update snapping detents
    var snapDetents = [CMTime]()
    // Detent order is semantic (they are processed sequentially and background
    // edges take precedence), so dedupe with a seen-set while appending in
    // order. Keyed by seconds because equal `CMTime`s with different
    // timescales may hash differently.
    var seenSeconds = Set<Double>()

    // Snap to the timeline start
    snapDetents.append(.zero)
    seenSeconds.insert(CMTime.zero.seconds)

    for clip in backgroundTrack.clips {
      guard let duration = clip.duration else { continue }
      // `Clip` bounds are transition-projected for rendering. Background clips
      // are normally contiguous, but a transition pulls each visual edge inward;
      // accumulating durations from zero would therefore move the detent away
      // from the rendered seam.
      let end = clip.displayTimeOffset + duration
      if seenSeconds.insert(end.seconds).inserted {
        snapDetents.append(end)
      }
    }

    // Include foreground and caption clip edges as snap points
    for clip in foregroundClips() + captionTrack.clips {
      let start = clip.displayTimeOffset
      if seenSeconds.insert(start.seconds).inserted {
        snapDetents.append(start)
      }
      if let duration = clip.duration {
        let end = start + duration
        if seenSeconds.insert(end.seconds).inserted {
          snapDetents.append(end)
        }
      }
    }

    // Assigning an equal array would still tick `objectWillChange`.
    if self.snapDetents != snapDetents {
      self.snapDetents = snapDetents
    }
  }
}
