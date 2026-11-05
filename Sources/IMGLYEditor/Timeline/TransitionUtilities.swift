import CoreMedia
@_spi(Internal) import IMGLYCore
import IMGLYEngine

private func transitionTime(_ seconds: Double) -> CMTime {
  CMTime(seconds: seconds)
}

/// Whether a clip that starts at `start` meets or overlaps a clip that ends at `end`.
private func clipsMeet(start: CMTime, end: CMTime) -> Bool {
  start <= end + transitionTime(0.001)
}

struct TransitionTrim: Equatable {
  var lead = CMTime.zero
  var tail = CMTime.zero
}

struct TransitionTiming {
  let rawDuration: CMTime
  let trim: TransitionTrim
}

@MainActor
func canShowTransition(
  engine: Engine,
  outgoing: DesignBlockID,
  incoming: DesignBlockID,
  outgoingEnd: CMTime,
  incomingStart: CMTime,
) -> Bool {
  (try? engine.block.supportsTransition(outgoing)) == true &&
    (try? engine.block.supportsTransition(incoming)) == true &&
    clipsMeet(start: incomingStart, end: outgoingEnd)
}

/// Returns the clip that follows `outgoing` on its track when the pair is eligible for a
/// transition: both clips support transitions and touch or overlap on the timeline.
/// Returns `nil` otherwise. Drives the default visibility of the inspector bar's
/// transition button.
@MainActor
public func transitionIncomingClip(engine: Engine, outgoing: DesignBlockID) -> DesignBlockID? {
  guard engine.block.isValid(outgoing),
        let parent = try? engine.block.getParent(outgoing),
        let children = try? engine.block.getChildren(parent) else { return nil }
  let sorted = children
    .sorted { (try? engine.block.getTimeOffset($0)) ?? 0 < (try? engine.block.getTimeOffset($1)) ?? 0 }
  guard let index = sorted.firstIndex(of: outgoing), index + 1 < sorted.count else { return nil }
  let incoming = sorted[index + 1]
  guard let outgoingStart = try? engine.block.getTimeOffset(outgoing),
        let outgoingDuration = try? engine.block.getDuration(outgoing),
        let incomingStart = try? engine.block.getTimeOffset(incoming),
        canShowTransition(
          engine: engine,
          outgoing: outgoing,
          incoming: incoming,
          outgoingEnd: transitionTime(outgoingStart + outgoingDuration),
          incomingStart: transitionTime(incomingStart),
        ) else { return nil }
  return incoming
}

@MainActor
func hasRealTransition(engine: Engine, outgoing: DesignBlockID) -> Bool {
  guard let transition = try? engine.block.getTransition(outgoing),
        engine.block.isValid(transition) else { return false }
  return true
}

@MainActor
func transitionOverlap(engine: Engine, outgoing: DesignBlockID, incoming: DesignBlockID) -> CMTime {
  guard let outgoingDuration = try? engine.block.getDuration(outgoing),
        let incomingDuration = try? engine.block.getDuration(incoming),
        let outgoingStart = try? engine.block.getTimeOffset(outgoing),
        let incomingStart = try? engine.block.getTimeOffset(incoming),
        canShowTransition(
          engine: engine,
          outgoing: outgoing,
          incoming: incoming,
          outgoingEnd: transitionTime(outgoingStart + outgoingDuration),
          incomingStart: transitionTime(incomingStart),
        ),
        let transition = try? engine.block.getTransition(outgoing),
        engine.block.isValid(transition),
        let transitionDuration = try? engine.block.getDuration(transition) else { return .zero }
  return transitionTime(max(0, min(transitionDuration, outgoingDuration / 2, incomingDuration / 2)))
}

@MainActor
func transitionTrim(engine: Engine, clip: DesignBlockID) -> TransitionTrim {
  let siblings = transitionTrackChildren(engine: engine, clip: clip)
  guard let index = siblings.firstIndex(of: clip) else { return .init() }
  let lead = index > 0
    ? transitionTime(transitionOverlap(engine: engine, outgoing: siblings[index - 1], incoming: clip).seconds / 2)
    : .zero
  let tail = index + 1 < siblings.count
    ? transitionTime(transitionOverlap(engine: engine, outgoing: clip, incoming: siblings[index + 1]).seconds / 2)
    : .zero
  return .init(lead: lead, tail: tail)
}

/// Converts a rendered duration to raw engine timing using the transition inset that
/// will apply after the duration changes. A transition edge is either capped or
/// contributes one quarter of the raw clip duration, yielding three linear regions.
@MainActor
func transitionTiming(engine: Engine, clip: DesignBlockID, renderedDuration: CMTime) -> TransitionTiming {
  let siblings = transitionTrackChildren(engine: engine, clip: clip)
  guard let index = siblings.firstIndex(of: clip) else {
    return .init(rawDuration: renderedDuration, trim: .init())
  }

  func trimCap(outgoing: DesignBlockID, incoming: DesignBlockID, adjacent: DesignBlockID) -> CMTime {
    guard transitionOverlap(engine: engine, outgoing: outgoing, incoming: incoming) > .zero,
          let transition = try? engine.block.getTransition(outgoing),
          let transitionDuration = try? engine.block.getDuration(transition),
          let adjacentDuration = try? engine.block.getDuration(adjacent) else { return .zero }
    return transitionTime(min(transitionDuration / 2, adjacentDuration / 4))
  }

  let leadingCap = index > 0
    ? trimCap(outgoing: siblings[index - 1], incoming: clip, adjacent: siblings[index - 1])
    : .zero
  let trailingCap = index + 1 < siblings.count
    ? trimCap(outgoing: clip, incoming: siblings[index + 1], adjacent: siblings[index + 1])
    : .zero
  let smallerCap = min(leadingCap, trailingCap)
  let largerCap = max(leadingCap, trailingCap)
  let smallerCapThreshold = transitionTime(smallerCap.seconds * 2)
  let largerCapThreshold = transitionTime(largerCap.seconds * 3 - smallerCap.seconds)

  let rawDuration: CMTime = switch renderedDuration {
  case ...smallerCapThreshold:
    transitionTime(renderedDuration.seconds * 2)
  case ...largerCapThreshold:
    transitionTime((renderedDuration.seconds + smallerCap.seconds) * 4 / 3)
  default:
    renderedDuration + smallerCap + largerCap
  }
  return .init(
    rawDuration: rawDuration,
    trim: .init(
      lead: min(leadingCap, transitionTime(rawDuration.seconds / 4)),
      tail: min(trailingCap, transitionTime(rawDuration.seconds / 4)),
    ),
  )
}

/// Maps each clip on `tracks` that has a transition to the clip that follows it on its track.
@MainActor
func transitionCuts(engine: Engine, tracks: [DesignBlockID]) -> [DesignBlockID: DesignBlockID?] {
  var cuts = [DesignBlockID: DesignBlockID?]()
  for track in tracks {
    guard let children = try? engine.block.getChildren(track) else { continue }
    for (index, clip) in children.enumerated() where hasRealTransition(engine: engine, outgoing: clip) {
      cuts.updateValue(index + 1 < children.count ? children[index + 1] : nil, forKey: clip)
    }
  }
  return cuts
}

/// Destroys the transition of each cut in `cuts` whose clip is now followed by a different clip. A transition belongs
/// to its cut, so it does not move to the new neighbour. Destroying it, unlike `removeTransition`, shifts no clip.
@MainActor
func removeChangedTransitionCuts(engine: Engine, cuts: [DesignBlockID: DesignBlockID?]) throws {
  for (outgoing, incoming) in cuts where engine.block.isValid(outgoing) {
    let transition = try engine.block.getTransition(outgoing)
    guard engine.block.isValid(transition) else { continue }
    let siblings = transitionTrackChildren(engine: engine, clip: outgoing)
    let next = siblings.firstIndex(of: outgoing).flatMap { $0 + 1 < siblings.count ? siblings[$0 + 1] : nil }
    guard next != incoming else { continue }
    try engine.block.destroy(transition)
  }
}

struct DropClip {
  let id: DesignBlockID
  /// The raw engine timing before the drop.
  let timeOffset: CMTime
  let duration: CMTime
  /// Where the drag draws the clip at the drop.
  let drawnStart: CMTime
  let drawnEnd: CMTime
}

/// Converts the drawn layout of a drop to raw engine offsets. `clips` are the clips of the target track in track order.
/// A clip in `movedClips` starts where it is drawn, and the drag draws `draggedClip` at its full length. A clip that
/// meets the clip before it in the drawing, where one of the two moved, joins that clip, overlapped by their
/// transition. `draggedClip` joins a next clip that did not move the same way, so a drop against either partner keeps
/// the pair as it was. Any other clip keeps its raw offset. Then each clip moves right until it overlaps its
/// predecessor by no more than their transition, because a removed transition gives the outgoing clip back the tail
/// that the timeline trimmed.
/// - Parameter movedClips: The dragged clip and the clips that the drop cascade moved.
/// - Returns: The raw offsets that differ from the current ones.
func dropOffsets(
  clips: [DropClip],
  draggedClip: DesignBlockID,
  movedClips: Set<DesignBlockID>,
  transitionOverlap: (_ outgoing: DesignBlockID, _ incoming: DesignBlockID) -> CMTime,
) -> [DesignBlockID: CMTime] {
  var offsets = [DesignBlockID: CMTime]()
  var previous: DropClip?
  var previousEnd = CMTime.zero
  var previousMoved = false
  for (index, clip) in clips.enumerated() {
    let overlap = previous.map { transitionOverlap($0.id, clip.id) } ?? .zero
    let joinedStart = previousEnd - overlap
    let isMoved = movedClips.contains(clip.id)
    let next = clips.indices.contains(index + 1) ? clips[index + 1] : nil
    var start = isMoved ? clip.drawnStart : clip.timeOffset
    if let previous, isMoved || previousMoved, clipsMeet(start: clip.drawnStart, end: previous.drawnEnd) {
      start = joinedStart
    } else if clip.id == draggedClip, let next, !movedClips.contains(next.id),
              clipsMeet(start: next.drawnStart, end: clip.drawnEnd) {
      start = next.timeOffset + transitionOverlap(clip.id, next.id) - clip.duration
    }
    if previous != nil {
      start = max(start, joinedStart)
    }
    if start != clip.timeOffset {
      offsets[clip.id] = start
    }
    previous = clip
    previousEnd = start + clip.duration
    previousMoved = isMoved || start != clip.timeOffset
  }
  return offsets
}

@MainActor
func clearConflictingAnimations(engine: Engine, outgoing: DesignBlockID) throws {
  let outAnimation = try engine.block.getOutAnimation(outgoing)
  if engine.block.isValid(outAnimation) {
    try engine.block.destroy(outAnimation)
  }
  if let incoming = transitionIncomingClip(engine: engine, outgoing: outgoing) {
    let inAnimation = try engine.block.getInAnimation(incoming)
    if engine.block.isValid(inAnimation) {
      try engine.block.destroy(inAnimation)
    }
  }
}

@MainActor
func transitionTrackChildren(engine: Engine, clip: DesignBlockID) -> [DesignBlockID] {
  guard let parent = try? engine.block.getParent(clip),
        let children = try? engine.block.getChildren(parent) else { return [] }
  return children
}

@MainActor
func trackHasRealTransition(engine: Engine, outgoing: DesignBlockID) -> Bool {
  transitionTrackChildren(engine: engine, clip: outgoing).contains { hasRealTransition(engine: engine, outgoing: $0) }
}
