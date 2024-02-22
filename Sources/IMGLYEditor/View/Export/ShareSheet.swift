import SwiftUI
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI

struct ShareSheet: ViewModifier {
  @EnvironmentObject private var interactor: Interactor

  func body(content: Content) -> some View {
    content
      .imgly.shareSheet($interactor.shareItem)
  }
}

@_spi(Internal) public extension IMGLY where Wrapped: View {
  @MainActor
  func shareSheet(
    _ item: Binding<ShareItem?>
  ) -> some View {
    wrapped.popover(item: item) { item in
      ShareView(item: item)
        .ignoresSafeArea()
        .imgly.presentationConfiguration(.adaptiveTiny)
        .presentationDetents([.medium])
    }
  }
}

@_spi(Internal) public enum ShareItem: IdentifiableByHash {
  case url([URL])
  case data([Data])
}

struct ShareView: UIViewControllerRepresentable {
  let item: ShareItem

  func makeUIViewController(context _: UIViewControllerRepresentableContext<ShareView>)
    -> UIActivityViewController {
    switch item {
    case let .url(url):
      return UIActivityViewController(activityItems: url, applicationActivities: nil)
    case let .data(data):
      return UIActivityViewController(activityItems: data, applicationActivities: nil)
    }
  }

  func updateUIViewController(
    _: UIActivityViewController,
    context _: UIViewControllerRepresentableContext<ShareView>
  ) {}
}
