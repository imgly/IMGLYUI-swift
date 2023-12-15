import SwiftUI

struct BottomBarCloseButton: View {
  @EnvironmentObject private var interactor: Interactor

  var body: some View {
    Button {
      interactor.bottomBarCloseButtonTapped()
    } label: {
      Label("Close", systemImage: "xmark.circle.fill")
        .symbolRenderingMode(.hierarchical)
        .foregroundColor(.secondary)
        .font(.title2)
    }
  }
}
