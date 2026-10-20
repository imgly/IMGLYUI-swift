import SwiftUI

struct CameraDialogState: Identifiable {
  let id = UUID()
  let title: LocalizedStringResource
  var message: String?
  let buttons: [Action]

  struct Action: Identifiable {
    let id = UUID()
    let title: LocalizedStringResource
    var role: ButtonRole?
    let action: @MainActor () -> Void
  }
}

/// One presentation for all camera-owned alerts; system permission prompts remain system-owned.
struct CameraDialog: View {
  @Binding var state: CameraDialogState?

  var body: some View {
    if let dialog = state {
      ZStack {
        Color.black.opacity(0.4).ignoresSafeArea()
          .contentShape(Rectangle())
        ViewThatFits(in: .vertical) {
          content(dialog)
          ScrollView { content(dialog) }
        }
        .frame(width: 270)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .cameraRotated()
        .padding(24)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) {
          guard let cancel = dialog.buttons.first(where: { $0.role == .cancel }) else { return }
          state = nil
          cancel.action()
        }
      }
    }
  }

  private func content(_ dialog: CameraDialogState) -> some View {
    VStack(spacing: 0) {
      VStack(spacing: 8) {
        Text(dialog.title).font(.headline)
        if let message = dialog.message {
          Text(message).font(.subheadline)
        }
      }
      .multilineTextAlignment(.center)
      .padding(20)
      ForEach(dialog.buttons) { action in
        Divider()
        Button(role: action.role) {
          state = nil
          action.action()
        } label: {
          Text(action.title)
            .fontWeight(action.role == .cancel ? .semibold : .regular)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(action.role == .destructive ? Color.red : Color.accentColor)
      }
    }
  }
}
