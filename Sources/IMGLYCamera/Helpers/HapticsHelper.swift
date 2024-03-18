import AVKit
import UIKit

/// Convenience access to haptic feedback generators.
@MainActor
class HapticsHelper {
  static let shared = HapticsHelper()
  var audioSession = AVAudioSession.sharedInstance()
  private let selectionFeedbackGenerator = UISelectionFeedbackGenerator()

  func cameraStartRecording() {
    enableHaptics()
    selectionFeedbackGenerator.selectionChanged()
  }

  func cameraStopRecording() {
    enableHaptics()
    selectionFeedbackGenerator.selectionChanged()
  }

  func cameraSelectFeature() {
    enableHaptics()
    selectionFeedbackGenerator.selectionChanged()
  }

  // MARK: -

  /// Haptics don’t play while recording by default.
  private func enableHaptics() {
    try? audioSession.setAllowHapticsAndSystemSoundsDuringRecording(true)
  }
}
