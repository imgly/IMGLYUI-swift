import CoreMedia
import Foundation
@_spi(Internal) import IMGLYCore

/// Manage timelines state and snap detents.
final class Timeline: ObservableObject, @unchecked Sendable {
  private(set) weak var interactor: (any TimelineInteractor)?

  private let pointsToSecondsRatio: CGFloat

  private let minZoomLevel: CGFloat
  private let maxZoomLevel: CGFloat

  /// The total time of the video track in this page.
  @Published private(set) var totalDuration = CMTime(seconds: 0)
  @Published private(set) var totalWidth: CGFloat = 0

  /// A formatted and localized string for the `totalDuration`.
  @Published private(set) var formattedTotalDuration = CMTime(seconds: 0).imgly.formattedDurationStringForPlayer()
  @Published private(set) var zoomLevel: CGFloat
  @Published private(set) var timelineRulerScaleInterval: TimeInterval = 0

  /// This is set to `true` by the `TimelineContentView` while zooming in and out.
  @Published var isPinchingZoom = false

  /// This is `true` before the timeline is presented.
  var needsInitialScrollOffset = true

  /// This keeps track of the vertical offset so we can restore it when the timeline is reopened.
  var verticalScrollOffset: CGFloat = 0

  /// This is set to `true` by the `TimelineScrollView` while moving the timeline.
  @Published var isDraggingTimeline = false

  /// The snap detents that are added temporarily if there is a selection.
  @Published var scrollSnapDetents = [SnapDetent]()

  /// The position of the guidelines that appear while a clip snaps to another clip. `nil` if nothing is currently
  /// snapping.
  /// This is updated by the `ClipTrimmingView`.
  @Published var snapIndicatorLinePositions = [CMTime]()

  init(
    interactor: any TimelineInteractor,
    configuration: TimelineConfiguration
  ) {
    self.interactor = interactor
    pointsToSecondsRatio = configuration.pointsToSecondsRatio
    minZoomLevel = configuration.minZoomLevel
    maxZoomLevel = configuration.maxZoomLevel
    zoomLevel = configuration.initialZoomLevel
    updateScaleInterval()
  }

  // MARK: - Timeline View Settings

  /// Sets the timeline zoom level.
  func setZoomLevel(_ zoomLevel: CGFloat) {
    let zoomLevel = min(maxZoomLevel, max(minZoomLevel, zoomLevel))
    guard zoomLevel != self.zoomLevel else { return }
    self.zoomLevel = zoomLevel
    updateTotalWidth()
    updateScaleInterval()
  }

  func setTotalDuration(_ duration: CMTime) {
    totalDuration = duration
    formattedTotalDuration = duration.imgly.formattedDurationStringForPlayer()
    updateTotalWidth()
  }

  // MARK: -

  func updateTotalWidth() {
    totalWidth = convertToPoints(time: totalDuration)
  }

  private func updateScaleInterval() {
    let timelineRulerScaleInterval: TimeInterval = switch zoomLevel {
    case 0 ..< 0.4:
      60
    case 0.4 ..< 0.6:
      40
    case 0.6 ..< 1:
      20
    case 1 ..< 2:
      10
    default:
      5
    }
    if self.timelineRulerScaleInterval != timelineRulerScaleInterval {
      self.timelineRulerScaleInterval = timelineRulerScaleInterval
    }
  }

  // MARK: - Timeline Calculations

  /// Converts a visual distance in the timeline to a timecode.
  func convertToTime(points: CGFloat) -> CMTime {
    CMTime(seconds: points / zoomLevel / pointsToSecondsRatio)
  }

  /// Converts a timecode to a visual distance in the timeline.
  func convertToPoints(time: CMTime) -> CGFloat {
    time.seconds * zoomLevel * pointsToSecondsRatio
  }

  // MARK: - Timeline Scroll Snapping

  /// Add detents to snap to the passed `clip`; usually the selected one.
  func addTimelineScrollSnapDetents(for clip: Clip, absoluteStartTime: CMTime, maxDuration: CMTime) {
    let snapTolerance = convertToTime(points: 5)

    var snapDetentIntervals: [CMTime] = []
    snapDetentIntervals.append(absoluteStartTime)

    if let duration = clip.duration {
      // When snapping to the end, we want to snap to the end of this track
      // rather than the start of the of the next track.
      snapDetentIntervals.append(absoluteStartTime + duration - CMTime(value: 1))
    } else {
      // If there is no duration, we snap to the end of the track.
      snapDetentIntervals.append(maxDuration)
    }

    scrollSnapDetents = snapDetentIntervals.map { detent in
      let snap = detent
      let range = (snap - snapTolerance) ... (snap + snapTolerance)
      return SnapDetent(range: range, snap: snap)
    }
  }

  /// Add detents to snap to the timeline ruler interval.
  func addRulerSnapDetents(totalDuration: CMTime) {
    let snapTolerance = convertToTime(points: 5)

    var snapDetentIntervals: [CMTime] = []

    snapDetentIntervals.append(CMTime(seconds: 0))

    let scaleInterval: TimeInterval = 10
    let markers = Array(stride(from: 0, through: totalDuration.seconds, by: scaleInterval))
    for marker in markers {
      snapDetentIntervals.append(CMTime(seconds: marker))
    }

    scrollSnapDetents = snapDetentIntervals.map { detent in
      let snap = detent
      let range = (snap - snapTolerance) ... (snap + snapTolerance)
      return SnapDetent(range: range, snap: snap)
    }
  }
}
