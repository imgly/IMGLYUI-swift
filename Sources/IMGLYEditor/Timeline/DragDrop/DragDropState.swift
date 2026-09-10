import CoreMedia
import Foundation
import IMGLYEngine
import SwiftUI

enum DropTarget: Equatable {
  /// `effectiveDuration` is the dragged clip's duration after the drop. `nil` means the
  /// clip keeps its original duration. A non-`nil` value means trim-to-fit: the tail
  /// is shortened so the clip fits between locked walls. Only ever set on
  /// `existingTrack` drops because that's the only path with locked siblings.
  case existingTrack(trackID: UUID, insertIndex: Int, timeOffset: CMTime, effectiveDuration: CMTime?)
  /// `insertAt` is a position within `TimelineDataSource.tracks` (UI array). The list
  /// renders reversed, so `insertAt = tracks.count` is the visual top, `0` the bottom.
  case newTrack(insertAt: Int, timeOffset: CMTime)
}

struct DragContext {
  let clipID: DesignBlockID
  let sourceTrackID: UUID
  let initialTimeOffset: CMTime
  let initialTouchLocation: CGPoint
  var currentTouchLocation: CGPoint
  var dropTarget: DropTarget?

  /// Horizontal scroll offset at drag start. Subtracted from the current offset so
  /// the drop slot keeps tracking the finger when auto-scroll shifts the timeline.
  let initialScrollOffset: CGFloat

  /// Finger offset from the dragged clip's top-leading corner at drag start (window
  /// space). The floating overlay subtracts these to keep the finger pinned to its
  /// initial spot on the clip.
  let grabOffsetX: CGFloat
  let grabOffsetY: CGFloat

  /// Each visited track's `Clip.timeOffset` snapshot, populated lazily so we can
  /// restore it when the pointer leaves.
  var trackSnapshots: [UUID: [DesignBlockID: CMTime]] = [:]
}

enum DragDropState: Equatable {
  case idle
  case dragging(DragContext)

  // Equality is intentionally narrow: `initialTimeOffset`, `initialScrollOffset`,
  // `grabOffsetX/Y`, and `trackSnapshots` are drag-start bookkeeping that don't
  // affect rendering, so excluding them avoids spurious observer re-fires without
  // missing any user-visible state change. `currentTouchLocation` and `dropTarget`
  // drive the floating overlay / drop-slot indicator, so they must participate.
  static func == (lhs: DragDropState, rhs: DragDropState) -> Bool {
    switch (lhs, rhs) {
    case (.idle, .idle):
      true
    case let (.dragging(l), .dragging(r)):
      l.clipID == r.clipID
        && l.sourceTrackID == r.sourceTrackID
        && l.currentTouchLocation == r.currentTouchLocation
        && l.dropTarget == r.dropTarget
    default:
      false
    }
  }

  var context: DragContext? {
    if case let .dragging(context) = self { context } else { nil }
  }

  var isDragging: Bool {
    if case .dragging = self { true } else { false }
  }
}
