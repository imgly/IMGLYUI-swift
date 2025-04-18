import Foundation

protocol BatchMutable {}

extension BatchMutable {
  /// Commit multiple changes in a batch.
  mutating func commit(_ changes: (_ model: inout Self) -> Void) {
    var temp = self
    changes(&temp)
    self = temp
  }
}
