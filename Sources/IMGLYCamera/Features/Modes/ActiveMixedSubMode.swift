/// Tracks which sub-mode the shutter is currently driving while `captureType == .mixed`.
enum ActiveMixedSubMode: Equatable, Sendable {
  case photo
  case video
}
