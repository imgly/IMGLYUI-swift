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
          .navigationTitle("Edit Text")
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
              Button("Done") {
                interactor.keyboardBarDismissButtonTapped()
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
