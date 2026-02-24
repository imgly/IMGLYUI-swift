import Photos
import SwiftUI
@_spi(Internal) import IMGLYCore

@_spi(Internal) public extension IMGLY where Wrapped: View {
  @MainActor
  @_spi(Internal) func limitedLibraryPicker(isPresented: Binding<Bool>,
                                            onComplete: @escaping () -> Void) -> some View {
    wrapped
      .background(
        LimitedLibraryPicker(isPresented: isPresented, onComplete: onComplete),
      )
  }
}

private struct LimitedLibraryPicker: UIViewControllerRepresentable {
  @Binding var isPresented: Bool
  let onComplete: () -> Void

  func makeUIViewController(context _: Context) -> UIViewController {
    UIViewController()
  }

  func updateUIViewController(_ uiViewController: UIViewController, context _: Context) {
    let isPickerVisible = uiViewController.presentedViewController != nil
    guard isPresented, !isPickerVisible else { return }

    Task {
      _ = await PHPhotoLibrary.shared().imgly.presentLimitedLibraryPicker(from: uiViewController)
      isPresented = false
      onComplete()
    }
  }
}
