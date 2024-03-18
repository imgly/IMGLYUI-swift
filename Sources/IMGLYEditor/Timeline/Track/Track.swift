import CoreMedia
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

  @Published var clips = [Clip]()
}
