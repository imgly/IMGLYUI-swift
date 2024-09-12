import CoreMedia
@_spi(Internal) import IMGLYCore
import IMGLYEngine
import SwiftUI

enum ClipType {
  case invalid
  case audio
  case image
  case shape
  case sticker
  case text
  case video
  case voiceOver
}

extension ClipType: CustomStringConvertible {
  var description: String {
    switch self {
    case .invalid: ""
    case .audio: "Audio Clip"
    case .image: "Image"
    case .shape: "Shape"
    case .sticker: "Sticker"
    case .text: "Text"
    case .video: "Video Clip"
    case .voiceOver: "Voiceover"
    }
  }
}

/// A clip in the timeline.
final class Clip: Identifiable, Hashable, ObservableObject, @unchecked Sendable {
  static func == (lhs: Clip, rhs: Clip) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  // MARK: -

  let id: DesignBlockID

  var fillID: DesignBlockID?
  var shapeID: DesignBlockID?
  var effectIDs = [DesignBlockID]()
  var blurID: DesignBlockID?

  @Published var clipType: ClipType = .invalid
  @Published var configuration = ClipConfiguration.default

  @Published var title: String = ""

  /// The total length of the clip’s footage as `CMTime` without any trims applied. It’s not a constant because we don’t
  /// always know the duration of an asset before it has been loaded.
  @Published var footageDuration: CMTime?

  /// The footage URI is used to detect changes when replacing the asset.
  @Published var footageURLString: String?

  /// Whether the clip can be trimmed
  @Published var allowsTrimming: Bool = true

  /// Whether the clip can be selected
  @Published var allowsSelecting: Bool = true

  /// Whether the clip has an audio track
  let hasAudio: Bool = false

  // This is the fill ID for videos, but the block ID for other types.
  @Published var trimmableID: DesignBlockID

  /// A positive time offset in seconds that is inserted *before* the start of clip.
  @Published var timeOffset: CMTime = .init(seconds: 0)

  /// A positive time offset as `CMTime` that is trimmed from the *start* of the clip.
  @Published var trimOffset: CMTime = .init(seconds: 0)

  /// The trimmed or looped duration in the timeline as `CMTime`
  @Published var duration: CMTime?

  /// A value between 0 and 1 that represents the volume of this `Clip`.
  @Published var audioVolume: Double = 1

  /// This can be set independently from the `audioVolume` so that a `Clip`’s volume can be restored after it has been
  /// temporarily muted.
  @Published var isMuted: Bool = false

  @Published var isInBackgroundTrack: Bool = false

  @Published var isLoading: Bool = false

  // MARK: -

  init(id: DesignBlockID) {
    self.id = id
    trimmableID = id
  }
}
