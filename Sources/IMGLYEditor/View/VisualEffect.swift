import SwiftUI

struct VisualEffect: UIViewRepresentable {
  let effect: UIVisualEffect

  func makeUIView(context _: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
    UIVisualEffectView()
  }

  func updateUIView(_ uiView: UIVisualEffectView, context _: UIViewRepresentableContext<Self>) {
    uiView.effect = effect
  }
}
