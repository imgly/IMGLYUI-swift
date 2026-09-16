import CoreMedia
@_spi(Internal) import IMGLYCore
import IMGLYEngine

private func transitionTime(_ seconds: Double) -> CMTime {
  CMTime(seconds: seconds)
}

struct TransitionTrim {
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
    incomingStart <= outgoingEnd + transitionTime(0.001)
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
