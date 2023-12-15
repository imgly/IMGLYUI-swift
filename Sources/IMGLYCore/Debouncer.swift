import Combine
import Foundation

@_spi(Internal) public class Debouncer<T>: ObservableObject {
  @Published @_spi(Internal) public var value: T
  @Published @_spi(Internal) public var debouncedValue: T

  @_spi(Internal) public init(initialValue: T, delay: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(500)) {
    _value = .init(initialValue: initialValue)
    _debouncedValue = .init(initialValue: initialValue)

    $value
      .debounce(for: delay, scheduler: DispatchQueue.main)
      .assign(to: &$debouncedValue)
  }
}
