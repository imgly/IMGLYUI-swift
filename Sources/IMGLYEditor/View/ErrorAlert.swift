import SwiftUI

struct ErrorAlert: ViewModifier {
  @EnvironmentObject private var interactor: Interactor

  let isSheet: Bool

  @State private var error = AlertState()
  private var isActive: Bool { isSheet == interactor.sheet.isPresented }

  @Environment(\.dismiss) private var dismiss

  func body(content: Content) -> some View {
    content
      .alert(error.details?.title ?? "", isPresented: $error.isPresented, presenting: error.details) { details in
        Button(details.dismissTitle) {}
          .onDisappear {
            if details.shouldDismiss {
              dismiss()
              details.dismissCallback?()
            }
          }
        if let confirmTitle = details.confirmTitle {
          Button(confirmTitle) {
            details.confirmCallback?()
          }
        }
      } message: { details in
        Text(details.message)
      }
      .onReceive(interactor.$error) { newValue in
        guard isActive, newValue != error else {
          return
        }
        error = newValue
      }
      .onChange(of: error) { newValue in
        guard isActive, newValue != interactor.error else {
          return
        }
        interactor.error = newValue
      }
  }
}

struct ErrorAlert_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
