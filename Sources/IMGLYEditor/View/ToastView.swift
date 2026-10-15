import SwiftUI

struct ToastView: View {
  let message: LocalizedStringResource
  let onDismiss: () -> Void

  var body: some View {
    HStack(spacing: 8) {
      Text(message)
        .font(.footnote)
        .foregroundStyle(.primary)
        .multilineTextAlignment(.leading)
      Spacer(minLength: 8)
      Button(action: onDismiss) {
        Image(systemName: "xmark")
          .font(.footnote.weight(.semibold))
          .foregroundStyle(.secondary)
          .padding(.vertical, 4)
          .padding(.horizontal, 6)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Dismiss")
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
  }
}
