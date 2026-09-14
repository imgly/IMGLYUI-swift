import CoreMedia
import SwiftUI

/// The timeline that visualizes tracks and clips in a scene.
struct TimelineView: View {
  @EnvironmentObject var interactor: AnyTimelineInteractor

  var body: some View {
    if let timeline = interactor.timelineProperties.timeline {
      GeometryReader { geometry in
        TimelineContentView()
          .environmentObject(timeline)
          .environmentObject(interactor.timelineProperties)
          .environmentObject(interactor.timelineProperties.player)
          .environmentObject(interactor.timelineProperties.dataSource)
          .environment(\.imglyTimelineConfiguration, interactor.timelineProperties.configuration)
          .environment(\.imglyViewportWidth, geometry.size.width)
          //  Video timelines should not flip; see: https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/SupportingRight-To-LeftLanguages/SupportingRight-To-LeftLanguages.html
          .environment(\.layoutDirection, .leftToRight)
      }
    } else {
      EmptyView()
    }
  }
}

extension EnvironmentValues {
  @Entry var imglyViewportWidth: CGFloat = 0
}
