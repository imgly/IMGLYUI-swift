import SwiftUI

struct AlertOverlay<Overlay: View>: ViewModifier {
  @Binding var isPresented: Bool
  var overlay: () -> Overlay

  func body(content: Content) -> some View {
    content
      .fullScreenCover(isPresented: $isPresented, content: {
        ZStack {
          Color.black.opacity(0.5)
            .ignoresSafeArea()
            .background {
              TransparentBackground()
            }
          overlay()
        }
        .onTapGesture {
          UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
      })
      .transaction { transaction in
        transaction.disablesAnimations = true
      }
  }

  private struct TransparentBackground: UIViewRepresentable {
    func makeUIView(context _: Context) -> UIView {
      let view = UIView()
      DispatchQueue.main.async {
        view.superview?.superview?.backgroundColor = .clear
      }
      return view
    }

    func updateUIView(_: UIView, context _: Context) {}
  }
}
