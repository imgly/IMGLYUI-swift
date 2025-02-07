import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

@_spi(Unstable) public struct DismissableTitledSheet<Content: View>: View {
  let title: LocalizedStringKey
  let content: () -> Content

  @_spi(Unstable) public init(_ title: LocalizedStringKey, @ViewBuilder content: @escaping () -> Content) {
    self.title = title
    self.content = content
  }

  @_spi(Unstable) public var body: some View {
    TitledSheet(title) {
      content()
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            SheetDismissButton()
              .buttonStyle(.borderless)
          }
        }
    }
  }
}

@_spi(Unstable) public struct TitledSheet<Content: View>: View {
  let title: LocalizedStringKey
  let content: () -> Content

  @_spi(Unstable) public init(_ title: LocalizedStringKey, @ViewBuilder content: @escaping () -> Content) {
    self.title = title
    self.content = content
  }

  @_spi(Unstable) public var body: some View {
    NavigationView {
      content()
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(title)
    }
    .navigationViewStyle(.stack)
    .introspect(.navigationStack, on: .iOS(.v16...)) { navigationController in
      let navigationBar = navigationController.navigationBar
      // Fix cases when `.navigationBarTitleDisplayMode(.inline)` does not work.
      navigationBar.prefersLargeTitles = false
    }
  }
}
