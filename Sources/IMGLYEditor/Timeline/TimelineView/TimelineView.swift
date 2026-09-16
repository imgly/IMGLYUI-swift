import CoreMedia
import SwiftUI

/// The timeline that visualizes tracks and clips in a scene.
struct TimelineView: View {
  @EnvironmentObject var interactor: AnyTimelineInteractor

  var body: some View {
    if let timeline = interactor.timelineProperties.timeline {
      GeometryReader { geometry in
        let globalOrigin = geometry.frame(in: .global).origin
        TimelineContentView()
          .environmentObject(timeline)
          .environmentObject(interactor.timelineProperties)
          .environmentObject(interactor.timelineProperties.player)
          .environmentObject(interactor.timelineProperties.dataSource)
          .environment(\.imglyTimelineConfiguration, interactor.timelineProperties.configuration)
          .environment(\.imglyViewportWidth, geometry.size.width)
          //  Video timelines should not flip; see: https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/SupportingRight-To-LeftLanguages/SupportingRight-To-LeftLanguages.html
          .environment(\.layoutDirection, .leftToRight)
          .overlay {
            NewTrackLineIndicatorView(
              globalOrigin: globalOrigin,
              viewportWidth: geometry.size.width,
            )
            .environmentObject(timeline)
            .environmentObject(interactor.timelineProperties)
            .environment(\.imglyTimelineConfiguration, interactor.timelineProperties.configuration)
          }
          .overlay {
            FloatingClipOverlayView(globalOrigin: globalOrigin)
              .environmentObject(timeline)
              .environmentObject(interactor.timelineProperties)
              .environmentObject(interactor.timelineProperties.dataSource)
              .environment(\.imglyTimelineConfiguration, interactor.timelineProperties.configuration)
          }
      }
    }
  }
}

extension EnvironmentValues {
  @Entry var imglyViewportWidth: CGFloat = 0
}
