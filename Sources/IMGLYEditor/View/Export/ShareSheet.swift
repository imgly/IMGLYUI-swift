import SwiftUI
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI

struct ShareSheet: ViewModifier {
  @EnvironmentObject private var interactor: Interactor

  func body(content: Content) -> some View {
    content
      .imgly.shareSheet(item: $interactor.shareItem)
  }
}

@_spi(Internal) public extension IMGLY where Wrapped: View {
  @MainActor
  func shareSheet(
    item: Binding<ShareItem?>,
    onDismiss: (() -> Void)? = nil
  ) -> some View {
    wrapped.sheet(item: item, onDismiss: onDismiss) { item in
      ShareView(item: item)
        .ignoresSafeArea()
        .imgly.presentationConfiguration(.adaptiveTiny)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
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
      UIActivityViewController(activityItems: url, applicationActivities: nil)
    case let .data(data):
      UIActivityViewController(activityItems: data, applicationActivities: nil)
    }
  }

  func updateUIViewController(
    _: UIActivityViewController,
    context _: UIViewControllerRepresentableContext<ShareView>
  ) {}
}
