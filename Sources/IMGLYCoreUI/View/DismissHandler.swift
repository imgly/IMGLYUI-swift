import SwiftUI
import UIKit

/// Detects when a SwiftUI view is truly dismissed (not just covered by another view).
///
/// This handler uses `viewDidDisappear` combined with hierarchy checks to reliably
/// detect dismissal for both UIKit-initiated and SwiftUI programmatic dismissals.
///
/// Detection logic:
/// - SwiftUI overlay: `view.window` remains non-nil, callback does NOT fire
/// - UIKit overlay: ancestor has `presentedViewController`, callback does NOT fire
/// - True dismissal: `view.window` is nil AND no ancestor is presenting, callback fires
struct DismissHandler: UIViewControllerRepresentable {
  let onDismiss: () -> Void

  func makeUIViewController(context _: Context) -> UIViewController {
    DismissDetectorViewController(onDismiss: onDismiss)
  }

  func updateUIViewController(_: UIViewController, context _: Context) {}

  private class DismissDetectorViewController: UIViewController {
    let onDismiss: () -> Void

    init(onDismiss: @escaping () -> Void) {
      self.onDismiss = onDismiss
      super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func viewDidDisappear(_ animated: Bool) {
      super.viewDidDisappear(animated)

      // Check if any ancestor is presenting something on top.
      // In UIKit, when a fullScreen modal is presented on top of another,
      // the underlying view's window becomes nil but we're not truly dismissed.
      var ancestor: UIViewController? = parent
      while let current = ancestor {
        if current.presentedViewController != nil {
          // An ancestor is presenting something - we're covered, not dismissed
          return
        }
        ancestor = current.parent
      }

      // No ancestor is presenting anything - check if truly dismissed
      // SwiftUI programmatic: view.window becomes nil
      // UIKit programmatic: view.window becomes nil
      if view.window == nil {
        onDismiss()
      }
    }
  }
}
