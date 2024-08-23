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

struct TimelineViewportWidthConfigurationKey: EnvironmentKey {
  static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
  var imglyViewportWidth: CGFloat {
    get { self[TimelineViewportWidthConfigurationKey.self] }
    set { self[TimelineViewportWidthConfigurationKey.self] = newValue }
  }
}
