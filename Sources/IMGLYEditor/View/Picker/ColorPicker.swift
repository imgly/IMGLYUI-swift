import SwiftUI
@_spi(Internal) import IMGLYCore

extension IMGLY where Wrapped: View {
  func colorPicker(
    _ title: LocalizedStringResource? = nil,
    isPresented: Binding<Bool>,
    selection: Binding<CGColor>,
    supportsOpacity: Bool = true,
    onEditingChanged: @escaping (Bool) -> Void = { _ in }
  ) -> some View {
    wrapped.background(ColorPickerSheet(title: title, isPresented: isPresented, selection: selection,
                                        supportsOpacity: supportsOpacity, onEditingChanged: onEditingChanged))
  }
}

private struct ColorPickerSheet: UIViewRepresentable {
  var title: LocalizedStringResource?
  @Binding var isPresented: Bool
  @Binding var selection: CGColor
  var supportsOpacity: Bool
  var onEditingChanged: (Bool) -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(selection: $selection, isPresented: $isPresented, onEditingChanged: onEditingChanged)
  }

  class Coordinator: NSObject, UIColorPickerViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
    @Binding var selection: CGColor
    @Binding var isPresented: Bool
    var didPresent = false
    var onEditingChanged: (Bool) -> Void
    var lastContinuously = false

    init(selection: Binding<CGColor>, isPresented: Binding<Bool>, onEditingChanged: @escaping (Bool) -> Void) {
      _selection = selection
      _isPresented = isPresented
      self.onEditingChanged = onEditingChanged
    }

    func colorPickerViewController(_: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
      // Workaround for `displayP3` color space as the engine does not convert it yet.
      let cgColor = color.cgColor
      if cgColor.colorSpace?.name == CGColorSpace.displayP3, let convertedColor = cgColor.converted(
        to: .init(name: CGColorSpace.sRGB)!,
        intent: .defaultIntent,
        options: nil
      ) {
        selection = convertedColor
      } else {
        selection = color.cgColor
      }
      if !continuously || continuously != lastContinuously {
        onEditingChanged(continuously)
      }
      lastContinuously = continuously
    }

    func colorPickerViewControllerDidFinish(_: UIColorPickerViewController) {
      isPresented = false
      didPresent = false
    }

    func presentationControllerDidDismiss(_: UIPresentationController) {
      isPresented = false
      didPresent = false
    }
  }

  @MainActor func getTopViewController(from view: UIView) -> UIViewController? {
    guard var top = view.window?.rootViewController else {
      return nil
    }
    while let next = top.presentedViewController {
      top = next
    }
    return top
  }

  func makeUIView(context _: Context) -> UIView {
    let view = UIView()
    view.isHidden = true
    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    if isPresented, !context.coordinator.didPresent {
      let modal = UIColorPickerViewController()
      modal.selectedColor = UIColor(cgColor: selection)
      modal.supportsAlpha = supportsOpacity
      if let title {
        modal.title = String(localized: title)
      } else {
        modal.title = nil
      }
      modal.delegate = context.coordinator
      modal.modalPresentationStyle = .popover
      modal.popoverPresentationController?.sourceView = uiView
      modal.popoverPresentationController?.sourceRect = uiView.bounds
      modal.presentationController?.delegate = context.coordinator
      let top = getTopViewController(from: uiView)
      top?.present(modal, animated: true)
      context.coordinator.didPresent = true
    }
  }
}
