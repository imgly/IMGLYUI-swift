import Foundation

enum ClipSpeedDefaults {
  static let compareEpsilon: Float = 0.001
  static let step: Float = 0.25
  static let minSpeed: Float = 0.25
  static let maxSpeed: Float = 10
  static let audioMaxSpeed: Float = 3
  static let speedInputDecimals = 2
  static let durationInputDecimals = 2
  static let speedSuffix = "×"
  static let audioSpeedCutoff: Float = 3
  static let durationInputWidth: CGFloat = 96
  static let speedInputWidth: CGFloat = 83
  static let rowHeight: CGFloat = 44
  static let inputHeight: CGFloat = 32
}
