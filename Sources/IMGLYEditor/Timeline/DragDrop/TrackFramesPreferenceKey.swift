import Foundation
import SwiftUI

/// Aggregates each `TrackView`'s window-space frame, keyed by `Track.id`. Drag & drop
/// reads this to map a pointer Y to a target track.
struct TrackFramesPreferenceKey: PreferenceKey {
  static let defaultValue: [UUID: CGRect] = [:]

  static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
    value.merge(nextValue(), uniquingKeysWith: { _, rhs in rhs })
  }
}
