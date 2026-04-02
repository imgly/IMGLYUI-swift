import Foundation

/// Helper to determine when to use a 'percentage slider',
/// with functions for mapping to/from percentage ranges.
///
/// A 'percentage slider' is a Slider whose display range is `0...100`
/// (or `-100...100` in certain cases).
/// This is a more intuitive user-facing slider range
/// than the fractional values used behind the scenes
/// to control shaders etc.
enum PercentageSliderHelper {
  /// We show percentage sliders (range `0...100`) whenever
  /// the supplied min and max parameters fall within the `-1...1` range.
  static func isPercentageSlider<T: BinaryFloatingPoint>(min: T, max: T) -> Bool {
    let absBelow1 = abs(min) <= 1 && abs(max) <= 1
    let different = min != max
    return absBelow1 && different
  }

  /// A special case of percentage slider, when min and max values are mirrored at 0.
  /// In that case, a range of `-100...100` is displayed.
  private static func isSymmetricalPercentageSlider<T: BinaryFloatingPoint>(min: T, max: T) -> Bool {
    let notZero = min != 0 && max != 0
    let sameAbs = abs(min) == abs(max)
    return isPercentageSlider(min: min, max: max) && notZero && sameAbs
  }

  /// Map a value in the range of `min...max` to the range of `0...100`
  /// (or `-100...100` when it is a symmetrical slider).
  static func valueToPercentage<T: BinaryFloatingPoint>(value: T, min: T, max: T) -> T {
    func valueToSteps(_ stepCount: T) -> T { (value - min) / ((max - min) / stepCount) }
    if isSymmetricalPercentageSlider(min: min, max: max) {
      return valueToSteps(200) - 100
    } else {
      return valueToSteps(100)
    }
  }

  /// Guess an appropriate step size from supplied min and max values.
  /// Arranges step so that it covers the whole range with 100 or 200 steps.
  static func stepFromMinMax<T: BinaryFloatingPoint>(min: T, max: T) -> T {
    if isSymmetricalPercentageSlider(min: min, max: max) {
      (max - min) / 200
    } else {
      (max - min) / 100
    }
  }

  private static let maxFractionDigits = 2

  /// Get the number of fractional digits from a number, capped at ``maxFractionDigits``.
  private static func countFractionalDigits(_ value: some BinaryFloatingPoint) -> Int {
    let str = "\(Double(value))"
    guard let dotIndex = str.lastIndex(of: ".") else { return 0 }
    let fraction = str[str.index(after: dotIndex)...]
    // Trailing zero means it's a whole number represented as e.g. "1.0"
    if fraction == "0" { return 0 }
    return Swift.min(fraction.count, maxFractionDigits)
  }

  /// Format a raw slider value for display, using the step to determine decimal places.
  static func formatValue<T: BinaryFloatingPoint>(value: T, step: T) -> String {
    let decimals = countFractionalDigits(step)
    return String(format: "%.\(decimals)f", Double(value))
  }
}
