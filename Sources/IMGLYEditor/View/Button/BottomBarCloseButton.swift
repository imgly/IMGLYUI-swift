import SwiftUI

struct BottomBarCloseButton: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    Button {
      interactor.bottomBarCloseButtonTapped()
    } label: {
      RoundedRectangle(cornerRadius: 8)
        .fill(colorScheme == .light ? Color(uiColor: .systemGray6) : Color(uiColor: .systemGray5))
        .frame(width: 30, height: 48)
        .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 2)
        .overlay {
          Image(systemName: "xmark")
            .font(.headline)
        }
        .accessibilityLabel("Close")
    }
    .buttonStyle(.plain)
  }
}
