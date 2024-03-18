import SwiftUI
import UIKit

/// This delegate is used via a pinch gesture recognizer that we insert via Swift Introspect.
/// SwiftUI’s magnification gesture handling conflicted with the scroll view gestures.
class TimelinePinchGestureRecognizerDelegate: NSObject, UIGestureRecognizerDelegate, ObservableObject {
  @Published var state = UIGestureRecognizer.State.ended
  @Published var scale: CGFloat = 1

  @objc func pinched(_ gestureRecognizer: UIPinchGestureRecognizer) {
    state = gestureRecognizer.state
    scale = gestureRecognizer.scale
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    if gestureRecognizer.numberOfTouches == 2,
       otherGestureRecognizer is ClipTrimmingPanGestureRecognizer {
      // Cancel the clip trimming gesture recognizer because this is definitely a pinch
      otherGestureRecognizer.isEnabled = false
      otherGestureRecognizer.isEnabled = true
      return true
    }
    return false
  }
}
