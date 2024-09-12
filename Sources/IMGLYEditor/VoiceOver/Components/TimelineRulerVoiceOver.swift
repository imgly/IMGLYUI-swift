import CoreMedia
import SwiftUI
@_spi(Internal) import IMGLYCore

/// A timeline ruler that adapts to the current zoom level.
struct TimelineRulerVoiceOver: View {
  @EnvironmentObject var interactor: AnyTimelineInteractor
  @EnvironmentObject var timeline: Timeline
  @EnvironmentObject var dataSource: TimelineDataSource

  @State var viewportWidth: CGFloat

  private let markerWidth: CGFloat = 3
  private let markerHeight: CGFloat = 3

  private var numberOfMarkers: Double {
    let drawingDuration = timeline.totalDuration + timeline.convertToTime(points: viewportWidth / 2)
    return ceil(TimeInterval(drawingDuration.seconds) / 10 * 10)
  }

  var body: some View {
    HStack(alignment: .center, spacing: 0) {
      let markers: [TimeInterval] = Array(
        stride(
          from: 0,
          through: numberOfMarkers,
          by: timeline.timelineRulerScaleInterval
        )
      )
      ForEach(markers, id: \.self) { marker in
        HStack {
          if timeline.timelineRulerScaleInterval == 5 {
            let ticks: [TimeInterval] = Array(stride(from: 1, through: 4, by: 1))
            Spacer()
            ForEach(ticks, id: \.self) { _ in
              Circle()
                .frame(width: markerWidth, height: markerHeight)
              Spacer()
            }
          } else {
            Circle()
              .frame(width: markerWidth, height: markerHeight)
          }
        }
        .frame(width: timeline.convertToPoints(time: CMTime(seconds: timeline.timelineRulerScaleInterval)))
        .overlay(alignment: .leading) {
          // Use a different formatting for markers under a minute
          let labelString = marker < 60
            ? CMTime(seconds: marker).imgly.formattedDurationStringForClip(showFractionalPart: false)
            : CMTime(seconds: marker).imgly.formattedDurationStringForPlayer()

          // Position the label’s center at the left edge of the marker section
          Text(labelString)
            .padding(.leading, 5)
            .alignmentGuide(.leading) { d in
              d.width / 2
            }
        }
      }
      Spacer()
    }
    .font(.footnote)
    .foregroundColor(.secondary)
    .frame(maxWidth: .infinity)
  }
}
