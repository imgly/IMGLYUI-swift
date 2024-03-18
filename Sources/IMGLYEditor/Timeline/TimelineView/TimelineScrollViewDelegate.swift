import SwiftUI
import UIKit

/// This delegate is used by a UIScrollView connected via SwiftUI-Introspect making the ScrollView state observable.
class TimelineScrollViewDelegate: NSObject, UIScrollViewDelegate, ObservableObject {
  @Published private(set) var isDraggingOrDecelerating = false
  @Published private(set) var isDragging = false
  @Published private(set) var isDecelerating = false
  @Published private(set) var contentOffset = CGPoint.zero

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    contentOffset = scrollView.contentOffset
  }

  func scrollViewWillBeginDragging(_: UIScrollView) {
    isDragging = true
    isDraggingOrDecelerating = true
  }

  func scrollViewDidEndDragging(_: UIScrollView, willDecelerate decelerate: Bool) {
    isDragging = false
    if !decelerate {
      isDraggingOrDecelerating = false
    }
  }

  func scrollViewWillBeginDecelerating(_: UIScrollView) {
    isDecelerating = true
  }

  func scrollViewDidEndDecelerating(_: UIScrollView) {
    isDecelerating = false
    isDraggingOrDecelerating = false
  }
}
