import SwiftUI

/// Container for the `ClipView`s.
struct TrackView: View {
  @EnvironmentObject var timeline: Timeline
  @EnvironmentObject var timelineProperties: TimelineProperties
  @Environment(\.imglyTimelineConfiguration) var configuration: TimelineConfiguration

  @ObservedObject var track: Track

  var body: some View {
    HStack(spacing: 0) {
      ForEach(track.clips, id: \.id) { clip in
        ClipView(
          clip: clip,
          isSelected: clip == timelineProperties.selectedClip,
          clipSpacing: configuration.clipSpacing
        )
        .onTapGesture(count: 1) {
          guard clip.allowsSelecting else {
            return
          }
          timeline.interactor?.select(id: clip.id)
        }
      }
    }
  }
}
