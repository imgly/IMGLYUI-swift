import Foundation

/// Arithmetic shared by every stepper and stepped slider. It imports no
/// SwiftUI or engine module, so it stays unit-testable.
@_spi(Internal) public enum NumberStepperMath {
  @_spi(Internal) public enum Direction: Equatable {
    /// Moves to the next grid point strictly above the current value.
    case up
    /// Moves to the next grid point strictly below the current value.
    case down
  }

  /// Fraction digits that `step` needs, at most 4: `0.01` and `0.25` need 2, `1` needs 0.
  /// The first power of ten that makes the step whole, not the leading zeros, which give 1 for `0.25`.
  @_spi(Internal) public static func decimals(forStep step: some BinaryFloatingPoint) -> Int {
    let magnitude = abs(Double(step))
    guard magnitude > 0 else { return 0 }
    var decimals = 0
    var scaled = magnitude
    // A tolerance, because `Float(0.01)` reads back as `0.009999999776…`.
    while decimals < 4, abs(scaled - scaled.rounded()) > 1e-6 * Swift.max(1, scaled) {
      decimals += 1
      scaled *= 10
    }
    return decimals
  }

  @_spi(Internal) public static func clamped<T: BinaryFloatingPoint>(_ value: T, to bounds: ClosedRange<T>) -> T {
    Swift.min(Swift.max(value, bounds.lowerBound), bounds.upperBound)
  }

  /// Nearest multiple of `step` measured from `origin`.
  @_spi(Internal) public static func snapped<T: BinaryFloatingPoint>(_ value: T, step: T, origin: T) -> T {
    guard step > 0 else { return value }
    let steps = ((value - origin) / step).rounded()
    return origin + steps * step
  }

  /// One button press, clamped to `bounds`. An off-grid `value` moves to the
  /// adjacent grid point in `direction`, not the nearest, so `.down` never raises it.
  /// Within `step / 100` of a grid point counts as on it.
  @_spi(Internal) public static func stepped<T: BinaryFloatingPoint>(
    _ value: T, direction: Direction, step: T, bounds: ClosedRange<T>,
  ) -> T {
    // No grid, and dividing by `step` gives NaN. `abs` keeps a negative step
    // directional.
    guard step > 0 else {
      let delta = direction == .up ? Swift.abs(step) : -Swift.abs(step)
      return clamped(value + delta, to: bounds)
    }
    let origin = bounds.lowerBound
    let nearest = snapped(value, step: step, origin: origin)
    let gridIndex = (value - origin) / step
    let moved: T = if abs(nearest - value) < step / 100 {
      direction == .up ? nearest + step : nearest - step
    } else if direction == .up {
      origin + gridIndex.rounded(.up) * step
    } else {
      origin + gridIndex.rounded(.down) * step
    }
    return clamped(moved, to: bounds)
  }
}
