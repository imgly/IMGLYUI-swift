import Foundation

/// Enumerates how many captures a session produces.
public enum CaptureCount: Equatable, Sendable {
  /// Produces a single capture and dismisses.
  case single
  /// Stacks multiple captures into the progress ring.
  case multi
}
