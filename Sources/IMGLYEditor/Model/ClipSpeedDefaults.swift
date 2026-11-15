import Foundation

enum ClipSpeedDefaults {
  static let step: Float = 0.25
  static let minSpeed: Float = 0.25
  static let maxSpeed: Float = 10
  static let audioMaxSpeed: Float = 3
  static let speedInputDecimals = 2
  static let durationInputDecimals = 2
  static let audioSpeedCutoff: Float = 3
  /// Duration has no natural step, and its field hides the stepper buttons,
  /// so this sizes only one move of the VoiceOver adjust gesture. Typed entry
  /// is unaffected: `NumberStepperField` applies a typed value as written.
  static let durationStep: Double = 0.1
  static let rowHeight: CGFloat = 44
}
