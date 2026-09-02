import CoreMedia
import IMGLYEngine
import SwiftUI

/// Contains `Clip`s. Is different from the `Track`s in the Engine: This `Track` reflects the visual tracks in the
/// timeline.
final class Track: ObservableObject, Hashable {
  static func == (lhs: Track, rhs: Track) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  let id = UUID()

  /// The engine track block ID when this UI track is backed by an engine `//ly.img.ubq/track` block.
  /// `nil` for standalone foreground clips that are direct page children.
  var engineTrackID: DesignBlockID?

  @Published var clips = [Clip]()
  @Published var transitionSeams = [TransitionSeam]()

  init(engineTrackID: DesignBlockID? = nil) {
    self.engineTrackID = engineTrackID
  }
}

struct TransitionSeam: Identifiable, Equatable {
  let outgoingID: DesignBlockID
  let incomingID: DesignBlockID
  let hasTransition: Bool
  let isCompact: Bool

  var id: String {
    "\(outgoingID)-\(incomingID)"
  }
}
