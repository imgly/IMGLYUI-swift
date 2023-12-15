import Combine
import UIKit

@MainActor
protocol KeyboardObserver {
  var keyboardPublisher: AnyPublisher<Bool, Never> { get }
}

extension KeyboardObserver {
  var keyboardPublisher: AnyPublisher<Bool, Never> {
    Publishers.Merge(
      NotificationCenter.default
        .publisher(for: UIResponder.keyboardWillShowNotification)
        .map { _ in true },

      NotificationCenter.default
        .publisher(for: UIResponder.keyboardWillHideNotification)
        .map { _ in false }
    )
    .eraseToAnyPublisher()
  }
}
