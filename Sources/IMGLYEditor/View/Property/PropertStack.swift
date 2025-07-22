import SwiftUI

struct PropertyStack<Content: View>: View {
  let title: LocalizedStringResource
  @ViewBuilder let content: () -> Content

  init(_ title: LocalizedStringResource, @ViewBuilder content: @escaping () -> Content) {
    self.title = title
    self.content = content
  }

  var body: some View {
    HStack {
      Text(title)
      Spacer()
      HStack(spacing: 32, content: content)
    }
    .padding([.trailing], 16)
    .labelStyle(.iconOnly)
    .buttonStyle(.borderless) // or .plain will do the job
  }
}
