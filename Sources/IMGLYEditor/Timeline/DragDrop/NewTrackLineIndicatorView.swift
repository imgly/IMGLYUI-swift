import CoreMedia
import IMGLYEngine
import SwiftUI

/// Horizontal line in the gap above/below/between foreground tracks signalling
/// "release here to create a new track".
struct NewTrackLineIndicatorView: View {
  @EnvironmentObject var timeline: Timeline
  @EnvironmentObject var timelineProperties: TimelineProperties
  @Environment(\.imglyTimelineConfiguration) var configuration: TimelineConfiguration

  /// Subtracted from `TrackFramesPreferenceKey`'s global frames to position the line
  /// in the overlay's local space.
  let globalOrigin: CGPoint
  let viewportWidth: CGFloat

  private let lineHeight: CGFloat = 3

  var body: some View {
    if case let .dragging(context) = timelineProperties.dragDropState,
       case let .newTrack(insertAt, _) = context.dropTarget,
       let lineY = resolveLineY(insertAt: insertAt) {
      let strong = playableRangeInViewport()
      ZStack(alignment: .leading) {
        // Faint base across the full viewport.
        RoundedRectangle(cornerRadius: lineHeight / 2)
          .fill(configuration.clipSelectionActiveColor.opacity(0.3))
          .frame(width: viewportWidth, height: lineHeight)
        // Strong section over the playable duration (matches the web timeline).
        if strong.width > 0 {
          RoundedRectangle(cornerRadius: lineHeight / 2)
            .fill(configuration.clipSelectionActiveColor)
            .frame(width: strong.width, height: lineHeight)
            .offset(x: strong.minX)
        }
      }
      .frame(width: viewportWidth, height: lineHeight, alignment: .leading)
      .position(x: viewportWidth / 2, y: lineY - globalOrigin.y)
      .allowsHitTesting(false)
    }
  }

  /// Local-space X range covering `[0, timeline.totalDuration]`, clamped to the viewport.
  private func playableRangeInViewport() -> (minX: CGFloat, width: CGFloat) {
    // Timeline content is `.padding(.horizontal, viewportWidth/2)`, so time 0 sits at
    // X = viewportWidth/2 in content space; scroll offset shifts that left.
    let scrollOffset = timelineProperties.horizontalScrollOffsetPoints
    let startX = viewportWidth / 2 - scrollOffset
    let totalDurationPoints = timeline.convertToPoints(time: timeline.totalDuration)
    let endX = startX + totalDurationPoints
    let clampedStart = max(0, min(viewportWidth, startX))
    let clampedEnd = max(0, min(viewportWidth, endX))
    return (clampedStart, max(0, clampedEnd - clampedStart))
  }

  /// Above the topmost / below the bottommost / midpoint between adjacent candidates.
  private func resolveLineY(insertAt: Int) -> CGFloat? {
    let dataSource = timelineProperties.dataSource
    let frames = timelineProperties.trackFrames
    let halfSpacing = configuration.trackSpacing / 2

    // Filter to the dragged clip's lane (audio vs visual) — otherwise a visual-source
    // drag with only audio tracks present would render the indicator below the audio
    // row even though the new track lands above it.
    let draggedIsAudio: Bool = {
      guard case let .dragging(context) = timelineProperties.dragDropState,
            let dragged = dataSource.findClip(id: context.clipID) else { return false }
      return dragged.clipType == .audio || dragged.clipType == .voiceOver
    }()

    let entries: [(index: Int, frame: CGRect)] = dataSource.tracks
      .enumerated()
      .compactMap { idx, track in
        guard track !== dataSource.backgroundTrack, let frame = frames[track.id] else {
          return nil
        }
        let trackIsAudio = track.clips.first.map { $0.clipType == .audio || $0.clipType == .voiceOver } ?? false
        guard trackIsAudio == draggedIsAudio else { return nil }
        return (idx, frame)
      }
      .sorted { $0.frame.minY < $1.frame.minY } // top → bottom

    // No foreground tracks yet — this is the background-source path where
    // Iteration 3 creates the first foreground track in the empty space above
    // the AddAudioButton. The button sits at the foreground stack's bottom
    // edge, which is `foregroundStackBottomInset` above the background frame
    // (same inset `TimelineContentView` uses to lay out the stack).
    guard let topmost = entries.first, let bottommost = entries.last else {
      guard let bgFrame = frames[dataSource.backgroundTrack.id] else { return nil }
      let addAudioButtonTop = bgFrame.minY - configuration.foregroundStackBottomInset
      return addAudioButtonTop - halfSpacing
    }

    if insertAt >= dataSource.tracks.count {
      return topmost.frame.minY - halfSpacing
    }
    if insertAt <= bottommost.index {
      return bottommost.frame.maxY + halfSpacing
    }
    // Reversed rendering: upper-on-screen has the larger dataSource index.
    for i in 0 ..< (entries.count - 1) {
      let upper = entries[i]
      let lower = entries[i + 1]
      if upper.index == insertAt {
        return (upper.frame.maxY + lower.frame.minY) / 2
      }
    }
    return nil
  }
}
