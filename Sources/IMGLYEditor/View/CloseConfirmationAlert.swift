import SwiftUI

struct CloseConfirmationAlert: ViewModifier {
  @EnvironmentObject private var interactor: Interactor

  func body(content: Content) -> some View {
    content
      .alert(
        Text(.imgly.localized("ly_img_editor_dialog_close_confirm_title")),
        isPresented: $interactor.isCloseConfirmationAlertPresented
      ) {
        Button(role: .cancel) {
          // nothing to do here
        } label: {
          Text(.imgly.localized("ly_img_editor_dialog_close_confirm_button_dismiss"))
        }
        Button(role: .destructive) {
          interactor.confirmClose()
        } label: {
          Text(.imgly.localized("ly_img_editor_dialog_close_confirm_button_confirm"))
        }
      } message: {
        Text(.imgly.localized("ly_img_editor_dialog_close_confirm_text"))
      }
  }
}

struct CloseConfirmationAlert_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
