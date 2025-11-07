import CoreMedia
import Foundation

@_spi(Internal) import IMGLYCore
import SwiftUI

extension EnvironmentValues {
  @Entry var imglyTimelineConfiguration = TimelineConfiguration()
}

/// Configure the appearance and behavior of the timeline.
struct TimelineConfiguration {
  /// The timeline will not allow trimming a clip to a shorter duration than this value.
  var minClipDuration = CMTime(seconds: 1)

  // MARK: - Scale & Zoom

  /// Initial
  ///  factor when the view appears on screen.
  var initialZoomLevel: CGFloat = 2
  /// Zoomed all the way out.
  var minZoomLevel: CGFloat = 0.6
  /// Zoomed all the way in.
  var maxZoomLevel: CGFloat = 6
  /// How many points per second in the timeline when the zoom is set to 100% (1.0).
  var pointsToSecondsRatio: CGFloat = 10

  // MARK: - Timeline Items

  /// The height of the background track.
  var backgroundTrackHeight: CGFloat = 36

  /// The height of non-video tracks.
  var trackHeight: CGFloat = 36
  /// The minimized height of a track in the timeline.
  var minTrackHeight: CGFloat = 2

  /// The vertical distance between tracks in the timeline.
  var trackSpacing: CGFloat = 4
  /// The horizontal distance between clips in a track in the timeline. The distance is removed while a clip is selected
  /// to make editing feel more precise.
  var clipSpacing: CGFloat = 1

  /// The width of the left and right trimming handles of a selected clip.
  var trimHandleWidth: CGFloat = 20
  /// The corner radius of clip items in the timeline.
  var cornerRadius: CGFloat = 8
  /// The height of the timeline ruler.
  var timelineRulerHeight: CGFloat = 16

  // MARK: - Colors

  /// The color of the overlay shape on selected clips in the timeline.
  var clipSelectionColor = Color.blue
  /// The color of the overlay shape on selected clips in the timeline while moving it and  while dragging one of the
  /// trim handles.
  var clipSelectionActiveColor = Color.yellow
  /// The color of the thin vertical line overlay in the timeline that indicates the current playback position.
  var playheadColor = Color.blue
  /// The color of the thin vertical line overlay’s shadow.
  var playheadShadowColor = Color.black.opacity(0.15)
  /// The color of the animated dotted lines that appear when a clip snaps to another clip.
  var timelineSnapIndicatorColor = Color.blue

  // MARK: - Clips

  var audioClipConfiguration = ClipConfiguration(
    color: Color.purple,
    backgroundColor: Color.purple.opacity(0.16),
    icon: Image(systemName: "music.note"),
  )

  var imageClipConfiguration = ClipConfiguration(
    color: Color.primary,
    backgroundColor: Color.secondary.opacity(0.5),
    icon: Image(systemName: "photo"),
  )

  var shapeClipConfiguration = ClipConfiguration(
    color: Color.primary,
    backgroundColor: Color.secondary.opacity(0.5),
    icon: Image(systemName: "square.on.circle"),
  )

  var stickerClipConfiguration = ClipConfiguration(
    color: Color.primary,
    backgroundColor: Color.secondary.opacity(0.5),
    icon: Image(systemName: "face.smiling"),
  )

  var textClipConfiguration = ClipConfiguration(
    color: Color.primary,
    backgroundColor: Color.secondary.opacity(0.5),
    icon: Image(systemName: "t.square"),
  )

  var videoClipConfiguration = ClipConfiguration(
    color: Color.primary,
    backgroundColor: Color.secondary.opacity(0.5),
    icon: Image(systemName: "play.rectangle"),
  )

  var voiceOverClipConfiguration = ClipConfiguration(
    color: Color.pink,
    backgroundColor: Color.pink.opacity(0.16),
    icon: Image(systemName: "mic.fill"),
  )

  var groupClipConfiguration = ClipConfiguration(
    color: Color.primary,
    backgroundColor: Color.secondary.opacity(0.5),
    icon: Image(systemName: "square.dashed"),
  )
}
