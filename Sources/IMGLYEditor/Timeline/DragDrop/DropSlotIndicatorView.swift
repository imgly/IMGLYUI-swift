import CoreMedia
import IMGLYEngine
import SwiftUI

/// Rounded-rectangle silhouette at the dragged clip's drop slot. Renders only when the
/// active `DropTarget` points at the track hosting this view.
struct DropSlotIndicatorView: View {
  @EnvironmentObject var timeline: Timeline
  @EnvironmentObject var timelineProperties: TimelineProperties
  @Environment(\.imglyTimelineConfiguration) var configuration: TimelineConfiguration

  let trackID: UUID

  var body: some View {
    if case let .dragging(context) = timelineProperties.dragDropState,
       case let .existingTrack(targetTrackID, _, timeOffset, effectiveDuration) = context.dropTarget,
       targetTrackID == trackID,
       let draggedClip = timelineProperties.dataSource.findClip(id: context.clipID),
       let duration = effectiveDuration ?? draggedClip.duration {
      let width = timeline.convertToPoints(time: duration)
      let leadingPadding = timeline.convertToPoints(time: timeOffset)
      RoundedRectangle(cornerRadius: configuration.cornerRadius)
        .fill(Color(.tertiarySystemBackground))
        .overlay(
          RoundedRectangle(cornerRadius: configuration.cornerRadius)
            .strokeBorder(configuration.clipSelectionActiveColor, lineWidth: 2),
        )
        .opacity(0.55)
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .padding(.leading, leadingPadding)
        .allowsHitTesting(false)
    }
  }
}
