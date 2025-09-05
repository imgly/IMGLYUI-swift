import SwiftUI
@_spi(Internal) import IMGLYCore

@_spi(Internal) public extension IMGLY where Wrapped: View {
  @MainActor
  func photoRollImportOverlay(onError: ((Error) -> Void)? = nil) -> some View {
    wrapped.modifier(PhotoRollImportOverlay(onError: onError))
  }
}

@MainActor
private struct PhotoRollImportOverlay: ViewModifier {
  let onError: ((Error) -> Void)?
  @State private var isImporting = false
  @State private var isOverlayVisible = false

  func body(content: Content) -> some View {
    ZStack {
      content

      if isOverlayVisible {
        ZStack {
          Color.black.opacity(0.3)
            .ignoresSafeArea(.all)

          VStack(spacing: 12) {
            ProgressView()
            Text(.imgly.localized("ly_img_editor_dialog_photo_roll_importing"))
              .font(.footnote)
          }
          .padding(24)
          .background {
            RoundedRectangle(cornerRadius: 8)
              .fill(.regularMaterial)
          }
          .padding(32)
        }
        .transition(.opacity)
      }
    }
    .animation(.easeInOut(duration: 0.3), value: isOverlayVisible)
    .onReceive(NotificationCenter.default.publisher(for: .PhotoRollImportStarted)) { _ in
      isImporting = true
    }
    .onReceive(NotificationCenter.default.publisher(for: .PhotoRollImportCompleted)) { notification in
      isImporting = false

      if let error = notification.userInfo?["error"] as? Error {
        onError?(error)
      }
    }
    .task(id: isImporting) {
      if isImporting {
        try? await Task.sleep(for: .seconds(1))

        if !Task.isCancelled {
          isOverlayVisible = true
        }
      } else {
        isOverlayVisible = false
      }
    }
  }
}
