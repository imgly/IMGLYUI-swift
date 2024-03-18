import CoreMedia
import Foundation

/// Represents a `range` of timecodes that should be snapped to the specified `snap` timecode.
struct SnapDetent {
  let range: ClosedRange<CMTime>
  let snap: CMTime
}
