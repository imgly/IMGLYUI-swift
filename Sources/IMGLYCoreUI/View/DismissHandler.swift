import SwiftUI
import UIKit

/// Detects when a SwiftUI view is truly dismissed (not just covered by another view).
///
/// This handler uses multiple detection mechanisms to reliably detect dismissal:
/// 1. `dismantleUIViewController` - Called when SwiftUI removes the view from hierarchy
///    (e.g., NavigationStack path changes, fullScreenCover dismissed)
/// 2. `viewDidDisappear` - Called for UIKit-initiated dismissals and as a fallback
///
/// Detection logic:
/// - SwiftUI removes view: `dismantleUIViewController` fires callback
/// - UIKit overlay: ancestor has `presentedViewController`, callback does NOT fire
/// - Navigation pop: ancestor has `isMovingFromParent` true, callback DOES fire
/// - True dismissal: `view.window` is nil AND no ancestor is presenting, callback fires
struct DismissHandler: UIViewControllerRepresentable {
  let onDismiss: () -> Void

  func makeUIViewController(context _: Context) -> DismissDetectorViewController {
    DismissDetectorViewController(onDismiss: onDismiss)
  }

  func updateUIViewController(_: DismissDetectorViewController, context _: Context) {}

  static func dismantleUIViewController(_ uiViewController: DismissDetectorViewController, coordinator _: ()) {
    // Called when SwiftUI removes this view from the hierarchy.
    // This handles NavigationStack path changes and modal dismissals.
    uiViewController.handleDismissFromSwiftUI()
  }

  class DismissDetectorViewController: UIViewController {
    let onDismiss: () -> Void
    private var hasFiredDismiss = false

    init(onDismiss: @escaping () -> Void) {
      self.onDismiss = onDismiss
      super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    /// Called from `dismantleUIViewController` when SwiftUI removes this view.
    func handleDismissFromSwiftUI() {
      guard !hasFiredDismiss else { return }
      hasFiredDismiss = true
      onDismiss()
    }

    override func viewDidDisappear(_ animated: Bool) {
      super.viewDidDisappear(animated)

      // Don't fire if already handled by dismantleUIViewController
      guard !hasFiredDismiss else { return }

      // Check if any ancestor is presenting something on top (modal case).
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

      // Check if any ancestor is being removed from the navigation stack.
      // isMovingFromParent is true when a view controller is being popped.
      ancestor = parent
      while let current = ancestor {
        if current.isMovingFromParent {
          // An ancestor is being removed - we're being dismissed
          hasFiredDismiss = true
          onDismiss()
          return
        }
        ancestor = current.parent
      }

      // Check if we're still in a navigation stack (push case vs pop case).
      // Find the first ancestor that's in a navigation context and check if
      // it's still in the stack. Don't continue checking other ancestors
      // after finding one, as that could incorrectly find the root view.
      ancestor = parent
      while let current = ancestor {
        if let navController = current.navigationController {
          // Found an ancestor in a navigation context
          if navController.viewControllers.contains(current) {
            // This ancestor is still in the navigation stack - pushed to background, not dismissed
            return
          }
          // Not in the stack - we've been popped, proceed to dismissal check
          break
        }
        ancestor = current.parent
      }

      // No ancestor is presenting anything and either not in a navigation context
      // or was removed from it. Check if truly dismissed.
      // SwiftUI programmatic: view.window becomes nil
      // UIKit programmatic: view.window becomes nil
      if view.window == nil {
        hasFiredDismiss = true
        onDismiss()
      }
    }
  }
}
