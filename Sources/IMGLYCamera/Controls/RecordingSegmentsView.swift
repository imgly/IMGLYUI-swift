import CoreMedia
@_spi(Internal) import IMGLYCore
import SwiftUI

/// A circular visualization that displays the recorded clips on the record button.
struct RecordingSegmentsView: View {
  @EnvironmentObject var camera: CameraModel
  @EnvironmentObject var recordingsManager: RecordingsManager

  @State private var normalizedSegmentPositions = [ClosedRange<Double>]()
  @State private var segmentsBackgroundStart: Double = 0
  @State private var segmentsBackgroundEnd: Double = 1

  @ScaledMetric private var segmentLineWidth: Double = 4

  private let normalizedDurationGap: Double = 0.01

  var body: some View {
    let state = camera.state

    Circle()
      .fill(.regularMaterial)
      .shadow(color: .black.opacity(0.3), radius: 1.5, x: 0, y: 1)
      .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 4)
      .animation(.linear(duration: 0.2), value: state)
      .overlay {
        ZStack {
          // White line
          Circle()
            .trim(
              from: segmentsBackgroundStart,
              to: segmentsBackgroundEnd
            )
            .rotation(.degrees(-90))
            .stroke(.white.opacity(0.5), lineWidth: state == .recording ? 0 : 2)
            .animation(.imgly.growShrinkQuick, value: state)
          // Segments
          Group {
            ForEach(
              Array(zip(normalizedSegmentPositions, normalizedSegmentPositions.indices)),
              id: \.1
            ) { position, index in
              let color = state == .recording && index != normalizedSegmentPositions.count - 1
                ? .white
                : camera.configuration.recordingColor
              Circle()
                .trim(from: position.lowerBound, to: position.upperBound)
                .rotation(.degrees(-90))
                .stroke(color, lineWidth: segmentLineWidth)
            }
          }
          .shadow(color: .black.opacity(0.25), radius: 1, x: 0, y: 0)
        }
      }
      .onChange(of: recordingsManager.clips) { _ in
        updateNormalizedSegmentPositions()
      }
      .onChange(of: recordingsManager.currentlyRecordedClipDuration) { _ in
        updateNormalizedSegmentPositions()
      }
      .onAppear {
        updateNormalizedSegmentPositions()
      }
  }

  func updateNormalizedSegmentPositions() {
    guard recordingsManager.recordedClipsDurations.count > 0 || recordingsManager.currentlyRecordedClipDuration != nil
    else {
      normalizedSegmentPositions = []
      segmentsBackgroundStart = 0
      segmentsBackgroundEnd = 1
      return
    }

    var recordedDurations = recordingsManager.recordedClipsDurations
    var totalClipsDuration = recordingsManager.recordedClipsTotalDuration

    if let currentlyRecordedClipDuration = recordingsManager.currentlyRecordedClipDuration {
      recordedDurations.append(currentlyRecordedClipDuration)
      // swiftlint:disable:next shorthand_operator
      totalClipsDuration = totalClipsDuration + currentlyRecordedClipDuration
    }
    // Limit the visualization to a sensible max duration even if there is no recording limit set
    let maxTotalDuration = camera.configuration.maxTotalDuration == .positiveInfinity
      ? CMTime(seconds: 60)
      : camera.configuration.maxTotalDuration
    var totalDuration = max(maxTotalDuration, totalClipsDuration)

    // Add the length of the visual gaps to the total duration to make calculations easier.
    let gapsCount = camera.state == .recording ? Double(recordedDurations.count + 1) : Double(recordedDurations.count)
    let gapsDuration = totalDuration.seconds * (gapsCount * normalizedDurationGap)
    // swiftlint:disable:next shorthand_operator
    totalDuration = totalDuration + CMTime(seconds: gapsDuration)

    let normalized = recordedDurations.reduce(into: [ClosedRange<Double>]()) { partialResult, value in
      guard value > .zero else { return }
      let lowerBound: Double = if let previousItem = partialResult.last {
        previousItem.upperBound + normalizedDurationGap
      } else {
        normalizedDurationGap / 2
      }

      var duration = value.seconds / totalDuration.seconds // - normalizedDurationGap
      duration = max(duration, 0)

      let upperBound = lowerBound + duration

      guard lowerBound <= upperBound else { return }
      partialResult.append(lowerBound ... upperBound)
    }

    normalizedSegmentPositions = normalized

    segmentsBackgroundStart = (normalized.last?.upperBound ?? 0) + normalizedDurationGap
    segmentsBackgroundEnd = 1 - normalizedDurationGap / 2
  }
}
