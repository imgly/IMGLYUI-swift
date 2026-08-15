import Foundation
import IMGLYEngine

/// A namespace for automatic caption generation.
///
/// Configuring a callback via ``EditorConfiguration/Builder/captionsGeneration(_:)`` adds a **Generate
/// Automatically** action to the Add Captions sheet. The editor owns the UI and imports the result; the
/// callback only turns the scene's audio into a captions file. The IMG.LY auto-captions plugin provides
/// one; custom implementations can use any speech-to-text backend.
public enum CaptionsGeneration {
  /// A callback that transcribes the scene's audible content into a captions file.
  ///
  /// - Parameter engine: The engine of the current editor, for reading the scene's audio and video
  ///   content.
  /// - Returns: The URL of a temporary SRT or VTT file with cue timings relative to the page timeline.
  ///   The editor imports the file, replacing any existing captions, then deletes it.
  /// - Throws: ``Error/noSpeech`` when the scene's audio contains no transcribable speech. Any other
  ///   error surfaces as a generic failure alert. The editor cancels the surrounding task when the user
  ///   taps Cancel, so implementations should stay cooperatively cancellable (`URLSession`'s async APIs
  ///   already are).
  public typealias Callback = @MainActor (_ engine: Engine) async throws -> URL

  /// Errors a ``Callback`` can throw to drive specific alert copy in the captions sheet.
  public enum Error: Swift.Error {
    /// No transcribable speech was found in the scene's audio.
    case noSpeech
  }
}
