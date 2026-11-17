import Foundation

/// Magnetic-detent state machine for a drag with discrete snap targets.
///
/// `Slider` reports absolute positions, not the deltas `ScalePicker` gets, so
/// this measures from the raw position and does not reuse its logic.
/// It imports no SwiftUI, so it stays unit-testable.
@_spi(Internal) public struct SnapDetents<T: BinaryFloatingPoint> {
  /// Where the state machine currently sits.
  @_spi(Internal) public enum State: Equatable {
    /// Arms once the value leaves every capture zone, so a drag that starts
    /// on a target does not latch.
    case disarmed
    /// Outside every capture zone. Captures the moment the value enters one.
    case armed
    /// Latched until the raw value is beyond the escape distance.
    case snapped(target: T)
  }

  /// The result of one ``advance(rawValue:pointsPerValue:)`` call.
  @_spi(Internal) public struct Advance {
    /// `rawValue`, or the captured target while latched onto one.
    @_spi(Internal) public let value: T
    /// `true` only on the call that captures a detent.
    @_spi(Internal) public let didCapture: Bool
  }

  /// Half-width, in points, of the zone that captures a detent.
  @_spi(Internal) public static var captureZonePoints: CGFloat {
    6
  }

  /// Points from the target that release a detent. Wider than the capture
  /// zone, so a detent does not flicker at its edge.
  private static var escapeDistancePoints: CGFloat {
    12
  }

  @_spi(Internal) public private(set) var state: State
  private let targets: [T]

  @_spi(Internal) public init(targets: [T], state: State = .disarmed) {
    self.targets = targets
    self.state = state
  }

  /// Call once per drag update. Persist ``state`` and pass it to
  /// `init(targets:state:)` on the next update.
  ///
  /// - Parameters:
  ///   - rawValue: This update's absolute value, before snapping.
  ///   - pointsPerValue: Screen points per unit of value. Zero or less
  ///     disarms and disables snapping for this update.
  /// - Returns: The value to write, and whether this update captured a detent.
  @_spi(Internal) public mutating func advance(rawValue: T, pointsPerValue: CGFloat) -> Advance {
    guard pointsPerValue > 0, let nearestTarget = nearestTarget(to: rawValue) else {
      state = .disarmed
      return Advance(value: rawValue, didCapture: false)
    }

    func points(from target: T) -> CGFloat {
      CGFloat(abs(rawValue - target)) * pointsPerValue
    }
    let isInCaptureZone = points(from: nearestTarget) <= Self.captureZonePoints

    switch state {
    case .disarmed:
      if !isInCaptureZone {
        state = .armed
      }
      return Advance(value: rawValue, didCapture: false)

    case .armed:
      guard isInCaptureZone else {
        return Advance(value: rawValue, didCapture: false)
      }
      state = .snapped(target: nearestTarget)
      return Advance(value: nearestTarget, didCapture: true)

    case let .snapped(target):
      guard points(from: target) <= Self.escapeDistancePoints else {
        // Beyond the escape distance is outside this target's capture zone,
        // so the next approach can capture again.
        state = .armed
        return Advance(value: rawValue, didCapture: false)
      }
      return Advance(value: target, didCapture: false)
    }
  }

  private func nearestTarget(to value: T) -> T? {
    targets.min { abs($0 - value) < abs($1 - value) }
  }
}
