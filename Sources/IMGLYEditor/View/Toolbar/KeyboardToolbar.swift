import SwiftUI

struct KeyboardToolbar: View {
  @EnvironmentObject private var interactor: Interactor

  @State private var height: CGFloat?

  var body: some View {
    if interactor.editMode == .text {
      NavigationView {
        Color.clear
          .background {
            GeometryReader { geo in
              Color.clear
                .preference(key: KeyboardToolbarSafeAreaInsetsKey.self, value: geo.safeAreaInsets)
            }
          }
          .navigationTitle(Text(.imgly.localized("ly_img_editor_edit_text_title")))
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
              Button {
                interactor.keyboardBarDismissButtonTapped()
              } label: {
                Text(.imgly.localized("ly_img_editor_common_button_done"))
              }
              .font(.body.weight(.bold))
            }
          }
      }
      .navigationViewStyle(.stack)
      .onPreferenceChange(KeyboardToolbarSafeAreaInsetsKey.self) { newValue in
        if newValue?.top != 0 {
          height = newValue?.top
        }
      }
      .frame(height: height)
    }
  }
}
