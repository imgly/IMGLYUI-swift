/// Wraps the result of the camera.
public enum CameraResult: Sendable {
  /// An array of recordings.
  case recording([Recording])
  /// The video that was reacted to and an array of reaction recordings.
  case reaction(video: Recording, reaction: [Recording])
}
