import CoreMedia
import IMGLYEngine
import SwiftUI

/// Renders the dragged clip "in flight" at the timeline root, so it can rise above
/// the source track's bounds and traverse other tracks vertically.
struct FloatingClipOverlayView: View {
  @EnvironmentObject var timeline: Timeline
  @EnvironmentObject var timelineProperties: TimelineProperties
  @Environment(\.imglyTimelineConfiguration) var configuration: TimelineConfiguration

  /// Subtracted from the gesture's window-space pointer to convert into local coords.
  let globalOrigin: CGPoint

  var body: some View {
    if case let .dragging(context) = timelineProperties.dragDropState,
       let clip = timelineProperties.dataSource.findClip(id: context.clipID),
       clip.clipType != .caption, // Captions slide in-lane; they never float.
       let duration = clip.duration {
      let width = timeline.convertToPoints(time: duration)
      let height = configuration.trackHeight

      let clipOriginX = context.currentTouchLocation.x - context.grabOffsetX - globalOrigin.x
      let clipOriginY = context.currentTouchLocation.y - context.grabOffsetY - globalOrigin.y

      floatingBody(clip: clip, isInvalidDropZone: isInvalidDropZone(context: context, clip: clip))
        .frame(width: width, height: height)
        .position(x: clipOriginX + width / 2, y: clipOriginY + height / 2)
        .allowsHitTesting(false)
    }
  }

  @ViewBuilder
  private func floatingBody(clip: Clip, isInvalidDropZone: Bool) -> some View {
    let cornerRadius = configuration.cornerRadius
    let borderColor = isInvalidDropZone
      ? configuration.clipDragInvalidColor
      : configuration.clipSelectionActiveColor
    RoundedRectangle(cornerRadius: cornerRadius)
      .fill(clip.configuration.backgroundColor)
      .overlay {
        if let provider = try? timelineProperties.thumbnailsManager.getProvider(clip: clip) {
          ClipBackgroundView(
            clip: clip,
            cornerRadius: cornerRadius,
            pointsTrimOffsetWidth: 0,
            thumbnailsProvider: AnyThumbnailsProvider(erasing: provider),
            labelWidth: 0,
          )
          .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
      }
      .overlay {
        if isInvalidDropZone {
          RoundedRectangle(cornerRadius: cornerRadius)
            .fill(configuration.clipDragInvalidColor.opacity(0.35))
        }
      }
      .overlay {
        RoundedRectangle(cornerRadius: cornerRadius)
          .strokeBorder(borderColor, lineWidth: 2)
      }
      .opacity(0.9)
      .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
  }

  /// True when the pointer is over a lane the dragged clip can't enter: the caption
  /// lane (any non-caption clip) or the background row (audio / voiceover).
  private func isInvalidDropZone(context: DragContext, clip: Clip) -> Bool {
    let dataSource = timelineProperties.dataSource
    let pointerY = context.currentTouchLocation.y

    if dataSource.hasCaptionClips,
       let captionFrame = timelineProperties.trackFrames[dataSource.captionTrack.id],
       pointerY <= captionFrame.maxY {
      return true
    }

    guard !clip.isInBackgroundTrack,
          !clip.clipType.allowedInBackgroundTrack else {
      return false
    }
    guard let bgFrame = timelineProperties.trackFrames[dataSource.backgroundTrack.id] else {
      return false
    }
    return bgFrame.minY <= pointerY && pointerY <= bgFrame.maxY
  }
}
