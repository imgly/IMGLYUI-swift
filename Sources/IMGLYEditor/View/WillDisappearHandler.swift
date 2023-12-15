import SwiftUI

struct WillDisappearHandler: UIViewControllerRepresentable {
  let onWillDisappear: () -> Void

  func makeUIViewController(context _: Context) -> UIViewController {
    ViewWillDisappearViewController(onWillDisappear: onWillDisappear)
  }

  func updateUIViewController(_: UIViewController, context _: Context) {}

  private class ViewWillDisappearViewController: UIViewController {
    let onWillDisappear: () -> Void

    init(onWillDisappear: @escaping () -> Void) {
      self.onWillDisappear = onWillDisappear
      super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      onWillDisappear()
    }
  }
}

struct WillDisappearHandler_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
