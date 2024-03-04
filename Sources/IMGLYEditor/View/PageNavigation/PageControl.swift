import SwiftUI

struct PageControl: UIViewRepresentable {
  @Binding var currentPage: Int
  let numberOfPages: Int

  func makeCoordinator() -> Coordinator {
    Coordinator(currentPage: $currentPage)
  }

  func makeUIView(context: Context) -> UIPageControl {
    let control = UIPageControl()
    control.numberOfPages = numberOfPages
    control.pageIndicatorTintColor = UIColor.label.withAlphaComponent(0.3)
    control.currentPageIndicatorTintColor = UIColor.label
    control.addTarget(context.coordinator, action: #selector(Coordinator.pageControlDidFire(_:)), for: .valueChanged)
    return control
  }

  func updateUIView(_ uiView: UIPageControl, context: Context) {
    context.coordinator.currentPage = $currentPage
    uiView.currentPage = currentPage
    uiView.numberOfPages = numberOfPages
    uiView.pageIndicatorTintColor = UIColor.label.withAlphaComponent(0.3)
    uiView.currentPageIndicatorTintColor = UIColor.label
  }

  class Coordinator {
    var currentPage: Binding<Int>

    init(currentPage: Binding<Int>) {
      self.currentPage = currentPage
    }

    @MainActor @objc func pageControlDidFire(_ control: UIPageControl) {
      currentPage.wrappedValue = control.currentPage
    }
  }
}
