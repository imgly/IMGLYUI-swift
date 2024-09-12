import SwiftUI

/// A view modifier that presents an alert when an identifiable error occurs.
struct ErrorAlertModifier: ViewModifier {
  @Binding var identifiableError: IdentifiableError?

  /// A struct representing an identifiable error.
  /// This is used to conform to SwiftUI's requirement for identifiable alert items.
  struct IdentifiableError: Identifiable {
    let id = UUID()
    let message: String

    /// Initializes a new `IdentifiableError` with a given message.
    init(_ message: String) {
      self.message = message
    }
  }

  func body(content: Content) -> some View {
    content
      .alert("Error", isPresented: Binding<Bool>(
        get: { identifiableError != nil },
        set: { if !$0 { identifiableError = nil } }
      )) {
        Button("OK", role: .cancel) {
          identifiableError = nil
        }
      } message: {
        if let error = identifiableError {
          Text(error.message)
        }
      }
  }
}

extension View {
  /// A convenience method to apply the `ErrorAlertModifier` to any view.
  func errorAlert(error: Binding<ErrorAlertModifier.IdentifiableError?>) -> some View {
    modifier(ErrorAlertModifier(identifiableError: error))
  }
}
