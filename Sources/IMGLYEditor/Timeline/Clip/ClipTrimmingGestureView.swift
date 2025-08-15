import SwiftUI
import UIKit

/// A wrapped transparent UIKit view to handle drag gestures.
struct ClipTrimmingGestureView: UIViewRepresentable {
  let delegate: ClipTrimmingPanGestureRecognizerDelegate

  func makeUIView(context _: Context) -> TransparentGestureView {
    TransparentGestureView(delegate: delegate)
  }

  func updateUIView(_: TransparentGestureView, context _: Context) {}
}

class TransparentGestureView: UIView {
  let gestureRecognizer: ClipTrimmingPanGestureRecognizer

  init(delegate: ClipTrimmingPanGestureRecognizerDelegate) {
    gestureRecognizer = ClipTrimmingPanGestureRecognizer(
      target: delegate,
      action: #selector(ClipTrimmingPanGestureRecognizerDelegate.panned(_:))
    )

    super.init(frame: .zero)
    addGestureRecognizer(gestureRecognizer)

    backgroundColor = .clear
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError()
  }
}
