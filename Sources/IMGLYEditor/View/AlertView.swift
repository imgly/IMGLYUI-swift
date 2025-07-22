import SwiftUI

struct AlertView<Content: View>: View {
  @Environment(\.dismiss) private var dismiss

  let title: LocalizedStringResource
  @ViewBuilder let content: Content
  let apply: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      Text(title)
        .font(.headline)
        .padding(.top, 16)
        .padding(.bottom, 8)
      content
      Divider()
      HStack {
        Button {
          dismiss()
        } label: {
          Text(.imgly.localized("ly_img_editor_dialog_resize_button_dismiss"))
            .frame(maxWidth: .infinity, maxHeight: 44)
            .foregroundStyle(.red)
        }
        Divider()
          .frame(height: 44)
        Button {
          apply()
          dismiss()
        } label: {
          Text(.imgly.localized("ly_img_editor_dialog_resize_button_confirm"))
            .frame(maxWidth: .infinity, maxHeight: 44)
            .fontWeight(.bold)
        }
      }
      .frame(height: 44)
    }
    .background(.regularMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .padding(.horizontal, 45)
  }
}
