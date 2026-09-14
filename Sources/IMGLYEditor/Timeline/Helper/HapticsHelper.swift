import UIKit

/// Convenience access to haptic feedback generators.
@MainActor
class HapticsHelper {
  static let shared = HapticsHelper()

  private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
  private let softImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
  private let selectionFeedbackGenerator = UISelectionFeedbackGenerator()

  func playPause() {
    impactFeedbackGenerator.impactOccurred()
  }

  func timelineSnap() {
    selectionFeedbackGenerator.selectionChanged()
  }

  func timelineTrimmingRubberband() {
    softImpactFeedbackGenerator.impactOccurred()
  }

  func timelineReorderSnap() {
    selectionFeedbackGenerator.selectionChanged()
  }

  func timelineReorderStart() {
    impactFeedbackGenerator.impactOccurred()
  }

  func timelineReorderFinish() {
    impactFeedbackGenerator.impactOccurred()
  }
}
