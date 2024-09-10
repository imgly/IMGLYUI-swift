import Foundation

struct AlertState: BatchMutable {
  var isPresented: Bool
  var details: Details?

  struct Details: Equatable {
    let message: String
    let shouldDismiss: Bool
  }

  /// Hide alert.
  init() {
    isPresented = false
  }

  /// Show alert for `error` and `dismiss` parent after dismissing the alert.
  init(_ error: Swift.Error, dismiss: Bool) {
    isPresented = true
    details = Details(message: error.localizedDescription, shouldDismiss: dismiss)
  }
}
