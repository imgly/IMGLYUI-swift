import Combine
import IMGLYCoreUI
import SwiftUI

/// A Countdown timer
final class CountdownTimer: ObservableObject {
  enum Status {
    case started
    case finished
    case cancelled
  }

  @Published private(set) var status = Status.finished

  private var timer: Publishers.Autoconnect<Timer.TimerPublisher>?
  private var subscription: AnyCancellable?
  private let interval: TimeInterval = 1

  @Published private(set) var totalSeconds: TimeInterval = 0
  @Published private(set) var remainingSeconds: TimeInterval = 0

  func start(seconds: TimeInterval, callback: (() -> Void)?) {
    cancel()
    status = .started

    totalSeconds = seconds
    remainingSeconds = seconds

    timer = Timer.publish(every: interval, on: .main, in: .common).autoconnect()

    subscription = timer?.sink(receiveValue: { [weak self] _ in
      guard let self else { return }
      remainingSeconds = max(0, remainingSeconds - interval)
      if remainingSeconds <= 0 {
        finished()
        callback?()
      }
    })
  }

  func cancel() {
    status = .cancelled
    timer?.upstream.connect().cancel()
    timer = nil
    subscription = nil
  }

  func finished() {
    status = .finished
    timer?.upstream.connect().cancel()
    timer = nil
    subscription = nil
  }
}

struct CountdownTimer_Previews: PreviewProvider {
  static var previews: some View {
    let engineSettings = EngineSettings(license: "")
    Camera(engineSettings) { _ in }
  }
}
