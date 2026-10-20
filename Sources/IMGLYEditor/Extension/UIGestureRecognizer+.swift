import UIKit

extension UIGestureRecognizer {
  /// The touch location in window space, converted through the view hierarchy.
  ///
  /// On the unfolded iPhone Duo, `location(in: nil)` arrives rotated a quarter turn against the window's own axes, so
  /// it disagrees with every view frame. The location in the recognizer's view is correct, so it is converted from
  /// there.
  var locationInWindow: CGPoint {
    guard let view else {
      return location(in: nil)
    }
    return view.convert(location(in: view), to: nil)
  }
}
