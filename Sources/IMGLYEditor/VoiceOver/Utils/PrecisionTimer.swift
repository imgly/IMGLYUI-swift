import Combine
import Foundation

final class PrecisionTimer {
  // MARK: - Properties

  private var timer: AnyCancellable?
  private let interval: TimeInterval
  private let callback: () -> Void
  private var isRunning = false
  private let queue = DispatchQueue(label: "IntervalTimerQueue", qos: .userInitiated)

  // MARK: - Initializers

  init(interval: TimeInterval, callback: @escaping () -> Void) {
    self.interval = interval
    self.callback = callback
  }

  deinit {
    stop()
  }

  // MARK: - Methods

  func start() {
    guard !isRunning else { return }
    isRunning = true
    timer = Timer.publish(every: interval, tolerance: 0.001, on: .main, in: .common)
      .autoconnect()
      .receive(on: queue)
      .sink { [weak self] _ in
        self?.callback()
      }
  }

  func stop() {
    timer?.cancel()
    timer = nil
    isRunning = false
  }
}
