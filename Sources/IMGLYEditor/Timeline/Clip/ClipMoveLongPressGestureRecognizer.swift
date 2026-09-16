import SwiftUI
import UIKit

/// Distinct subclass so gesture delegates can identify the move drag vs. trim pans
/// or the scroll-view pan. SwiftUI gestures on views inside a `UIScrollView` starve
/// the scroll's pan recognizer; UIKit recognizer coordination + `cancelsTouchesInView`
/// gives us the iOS reorder idiom for free.
final class ClipMoveLongPressGestureRecognizer: UILongPressGestureRecognizer {}

/// Translation is relative to the initial touch location, so downstream code can treat
/// it like a `UIPanGestureRecognizer`'s `translation(in:)`.
final class ClipMoveLongPressGestureRecognizerDelegate: NSObject, ObservableObject {
  enum Phase: Equatable {
    case idle
    case began
    case changed
    case ended
    case cancelled
  }

  @Published var phase: Phase = .idle
  @Published var translation: CGPoint = .zero
  /// Absolute window-space location, used by drag & drop to resolve the target track
  /// independent of scroll offset.
  @Published var windowLocation: CGPoint = .zero
  /// Touch location in the clip's local space at `.began`. The host view fills the
  /// clip's bounds, so `.x` is directly the grab offset from the clip's leading edge.
  @Published var initialLocationInView: CGPoint = .zero

  @objc func handle(_ recognizer: UILongPressGestureRecognizer) {
    switch recognizer.state {
    case .began:
      initialLocationInView = recognizer.location(in: recognizer.view)
      translation = .zero
      windowLocation = recognizer.location(in: nil)
      phase = .began
    case .changed:
      let current = recognizer.location(in: recognizer.view)
      translation = CGPoint(
        x: current.x - initialLocationInView.x,
        y: current.y - initialLocationInView.y,
      )
      windowLocation = recognizer.location(in: nil)
      phase = .changed
    case .ended:
      phase = .ended
    case .cancelled, .failed:
      phase = .cancelled
    default:
      break
    }
  }

  func reset() {
    phase = .idle
    translation = .zero
    windowLocation = .zero
    initialLocationInView = .zero
  }
}

struct ClipMoveLongPressGestureView: UIViewRepresentable {
  let delegate: ClipMoveLongPressGestureRecognizerDelegate

  func makeUIView(context _: Context) -> TransparentLongPressGestureView {
    TransparentLongPressGestureView(delegate: delegate)
  }

  func updateUIView(_: TransparentLongPressGestureView, context _: Context) {}
}

final class TransparentLongPressGestureView: UIView {
  let gestureRecognizer: ClipMoveLongPressGestureRecognizer

  init(delegate: ClipMoveLongPressGestureRecognizerDelegate) {
    gestureRecognizer = ClipMoveLongPressGestureRecognizer(
      target: delegate,
      action: #selector(ClipMoveLongPressGestureRecognizerDelegate.handle(_:)),
    )
    gestureRecognizer.minimumPressDuration = 0.5 // standard iOS reorder timing
    // Tight tolerance: any real pan fails the long-press quickly so the scroll view's
    // pan (with its ~5pt threshold) can take over.
    gestureRecognizer.allowableMovement = 10

    super.init(frame: .zero)
    backgroundColor = .clear
    addGestureRecognizer(gestureRecognizer)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError()
  }
}
