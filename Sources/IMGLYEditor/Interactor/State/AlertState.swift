import Foundation

struct AlertState: BatchMutable {
  var isPresented: Bool
  var details: Details?

  struct Details: Equatable {
    let title: String
    let message: String
    let shouldDismiss: Bool
    let dismissTitle: String
    let confirmTitle: String?
    var confirmCallback: (() -> Void)?

    init(
      title: String,
      message: String,
      shouldDismiss: Bool,
      dismissTitle: String = "Dismiss",
      confirmTitle: String? = nil,
      confirmCallback: (() -> Void)? = nil
    ) {
      self.title = title
      self.message = message
      self.shouldDismiss = shouldDismiss
      self.dismissTitle = dismissTitle
      self.confirmTitle = confirmTitle
      self.confirmCallback = confirmCallback
    }

    static func == (lhs: Details, rhs: Details) -> Bool {
      lhs.title == rhs.title &&
        lhs.message == rhs.message &&
        lhs.shouldDismiss == rhs.shouldDismiss &&
        lhs.dismissTitle == rhs.dismissTitle &&
        lhs.confirmTitle == rhs.confirmTitle
    }
  }

  /// Hide alert.
  init() {
    isPresented = false
  }

  /// Show alert for `error` and `dismiss` parent after dismissing the alert.
  init(_ error: Swift.Error, dismiss: Bool) {
    isPresented = true
    details = Details(title: "Error", message: error.localizedDescription, shouldDismiss: dismiss)
  }

  /// Show alert for `message` and `dismiss` parent after dismissing the alert.
  init(_ title: String, message: String, dismiss: Bool) {
    isPresented = true
    details = Details(title: title, message: message, shouldDismiss: dismiss)
  }

  /// Show alert for `message` with custom titles and callback
  init(_ title: String,
       message: String,
       dismiss: Bool,
       dismissTitle: String = "Cancel",
       confirmTitle: String,
       confirmCallback: @escaping (() -> Void)) {
    isPresented = true
    details = Details(title: title,
                      message: message,
                      shouldDismiss: dismiss,
                      dismissTitle: dismissTitle,
                      confirmTitle: confirmTitle,
                      confirmCallback: confirmCallback)
  }
}
