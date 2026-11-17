import SwiftUI

struct ReorderOptions: View {
  @EnvironmentObject var interactor: Interactor

  var body: some View {
    VStack(alignment: .center) {
      ReorderingView(track: interactor.timelineProperties.dataSource.backgroundTrack)
        .environmentObject(AnyTimelineInteractor(erasing: interactor))
    }
    .background(Color(.systemGroupedBackground))
  }
}
