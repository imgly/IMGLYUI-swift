import Foundation

@_spi(Internal) public extension Comparable {
  func clamped(to limits: ClosedRange<Self>) -> Self {
    min(max(self, limits.lowerBound), limits.upperBound)
  }

  mutating func clamp(to limits: ClosedRange<Self>) {
    self = clamped(to: limits)
  }
}
