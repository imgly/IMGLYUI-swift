import SwiftUI

struct CustomizableTitledSheet<Content: View, Leading: View, Trailing: View>: View {
  let title: LocalizedStringKey
  let content: () -> Content
  let leading: () -> Leading
  let trailing: () -> Trailing

  init(
    _ title: LocalizedStringKey,
    @ViewBuilder content: @escaping () -> Content,
    @ViewBuilder leading: @escaping () -> Leading,
    @ViewBuilder trailing: @escaping () -> Trailing = { SheetDismissButton()
      .buttonStyle(.borderless)
    }
  ) {
    self.title = title
    self.content = content
    self.leading = leading
    self.trailing = trailing
  }

  var body: some View {
    TitledSheet(title) {
      content()
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            leading()
          }

          ToolbarItem(placement: .navigationBarTrailing) {
            trailing()
          }
        }
    }
  }
}
