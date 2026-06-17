/// Wraps the result of the camera.
public enum CameraResult: Sendable {
  /// Recordings are now wrapped as `Capture.video` inside `.capture(...)`. Use `[Capture].videos`
  /// to extract `[Recording]` from a heterogeneous capture stack.
  @available(*, unavailable, renamed: "capture",
             message: "Recordings are wrapped as Capture.video. Use captures.videos to extract them.")
  case recording([Recording])

  /// Emitted when `cameraMode == .reaction(...)`: the host-supplied video the user reacted to,
  /// paired with the user's recordings (one `Recording` per shutter press).
  case reaction(video: Recording, reaction: [Recording])

  /// Emitted for any non-reaction session. Preserves user-press order and may interleave
  /// `.photo(Photo)` and `.video(Recording)` for `.mixed` captures, or contain pure `.video`
  /// entries for `.video` sessions.
  case capture([Capture])
}

public extension [Capture] {
  /// Extracts video recordings from a heterogeneous capture stack. Migration shortcut for hosts
  /// that previously consumed `CameraResult.recording([Recording])`.
  var videos: [Recording] {
    compactMap { capture in
      if case let .video(recording) = capture { return recording }
      return nil
    }
  }
}
