import SwiftUI
import UIKit

// We use a custom gesture recognizer subclass to be able to identify these specific drags
// and distinguish them from the UIScrollView’s built-in UIPanGestureRecognizers.
class ClipTrimmingPanGestureRecognizer: UIPanGestureRecognizer {}

class ClipTrimmingPanGestureRecognizerDelegate: NSObject, UIGestureRecognizerDelegate, ObservableObject {
  @Published var state = UIGestureRecognizer.State.ended
  @Published var translation = CGPoint.zero
  /// The absolute touch location in window (global) space. Used by drag & drop to resolve
  /// which track the pointer is over, independent of scroll offset.
  @Published var windowLocation = CGPoint.zero

  @objc func panned(_ gestureRecognizer: UIPanGestureRecognizer) {
    state = gestureRecognizer.state
    translation = gestureRecognizer.translation(in: gestureRecognizer.view)
    windowLocation = gestureRecognizer.location(in: nil)
  }
}
