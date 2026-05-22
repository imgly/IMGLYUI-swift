import UIKit

/// Convenience access to haptic feedback generators.
@MainActor
class HapticsHelper {
  static let shared = HapticsHelper()

  private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
  private let mediumImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
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
    // Stronger thump than the regular reorder snap so the long-press → drag transition
    // feels distinct from incidental haptics.
    mediumImpactFeedbackGenerator.impactOccurred()
  }

  func timelineReorderFinish() {
    impactFeedbackGenerator.impactOccurred()
  }
}
