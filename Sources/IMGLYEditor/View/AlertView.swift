import SwiftUI

struct AlertView<Content: View>: View {
  @Environment(\.dismiss) private var dismiss

  let title: LocalizedStringKey
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
          Text(.init("Cancel"))
            .frame(maxWidth: .infinity, maxHeight: 44)
            .foregroundStyle(.red)
        }
        Divider()
          .frame(height: 44)
        Button {
          apply()
          dismiss()
        } label: {
          Text(.init("Apply"))
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
