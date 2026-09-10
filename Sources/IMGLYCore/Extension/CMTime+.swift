import CoreMedia
import Foundation

extension CMTime: IMGLYCompatible {}

@_spi(Internal) public extension CMTime {
  /// Convenience init that applies the shared `imgly.timescale`.
  init(seconds: Double) {
    self.init(seconds: seconds, preferredTimescale: Self.imgly.timescale)
  }

  /// Convenience init that applies the shared `imgly.timescale`.
  init(value: CMTimeValue) {
    self.init(value: value, timescale: Self.imgly.timescale)
  }
}

@_spi(Internal) public extension IMGLY where Wrapped == CMTime {
  // MARK: - Timescale

  /// The IMG.LY `timescale` represents the framerate per second that will be used for calculations.
  static let timescale: CMTimeScale = 9000

  // MARK: - Formatting

  /// Returns a string with a localized representation of the timecode.
  /// Durations are rounded towards zero.
  ///
  /// - `13.4` are displayed as `13s`
  /// - `-13.4` are displayed as `-13s`
  /// We keep one fractional digit for single-digit durations if `alwaysRounded` is `false`:
  /// - `9.25` are displayed as `9.2s`
  /// - `-9.25` are displayed as `-9.2s`
  func formattedDurationStringForClip(showFractionalPart: Bool = true) -> String {
    guard !wrapped.seconds.isNaN else { return "NaN" }
    guard wrapped.seconds <= Double(Int.max) else { return "\u{221E}" } // Too large; probably .infinity (\u{221E} = ∞)

    let seconds = abs(wrapped.seconds) >= 10
      ? wrapped.seconds.rounded(.towardZero)
      : (wrapped.seconds * 10).rounded(.towardZero) / 10

    let formatted = Duration.seconds(seconds)
      .formatted(.units(allowed: [.minutes, .seconds],
                        width: .narrow,
                        fractionalPart: showFractionalPart && seconds < 10 ? .show(length: 1) : .hide))
    return formatted
  }

  /// Returns a string with a localized representation of the timecode.
  /// Rounding down (*not* towards zero) is the default for timecodes, because it feels correct in a timeline.
  /// - Parameter roundDownToSeconds: Set this to `false` to avoid rounding. Default is `true`.
  ///
  /// - `4.8` seconds are displayed as `0:04`, not `0:05`
  /// - `-4.8` seconds are displayed as `-0:05`, not `-0:04`
  func formattedDurationStringForPlayer(roundDownSeconds: Bool = true) -> String {
    guard !wrapped.seconds.isNaN else { return "NaN" }
    let seconds = roundDownSeconds ? wrapped.seconds.rounded(.down) : wrapped.seconds
    let formatted = Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond))
    return formatted
  }

  /// Workaround because multiplying `CMTime` with `-1` directly doesn’t work.
  func makeNegative() -> CMTime {
    CMTime(value: -1 * wrapped.value, timescale: Self.timescale)
  }

  /// Converts the duration in seconds to a formatted string for the player.
  /// The format of the string is "MM:SS,MS", where:
  /// - MM: Minutes (two digits)
  /// - SS: Seconds (two digits)
  /// - MS: Milliseconds (two digits, rounded)
  /// - Returns: A string representing the timecode in the format "MM:SS,MS".
  func formattedDurationMillisecondsStringForPlayer() -> String {
    guard !wrapped.seconds.isNaN else { return "NaN" }
    let totalSeconds = wrapped.seconds
    let fullMilliseconds = (totalSeconds.truncatingRemainder(dividingBy: 1)) * 1000
    let roundedMilliseconds = Int(fullMilliseconds / 10)
    let wholeSeconds = Int(totalSeconds) % 60
    let minutes = Int(totalSeconds) / 60

    // Formatting string now expects two digits for milliseconds, correctly rounded
    return String(format: "%02d:%02d,%02d", minutes, wholeSeconds, roundedMilliseconds)
  }
}
