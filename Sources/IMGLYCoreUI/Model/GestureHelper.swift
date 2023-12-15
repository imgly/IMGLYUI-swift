import UIKit

class GestureHelper: ObservableObject {
  @Published var state: UIGestureRecognizer.State?

  @MainActor @objc func handleGesture(_ recognizer: UIGestureRecognizer) {
    state = recognizer.state
  }
}
