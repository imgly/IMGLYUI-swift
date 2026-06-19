import Foundation
import IMGLYEngine

public extension EngineError {
  /// The customer-facing message to display for this engine error.
  ///
  /// This resolves the same copy CE.SDK's built-in error dialogs show, so you can reuse it in your
  /// own error handling without reimplementing the lookup. It looks up the authored
  /// `ly_img_engine_error_<code>` string in the `IMGLYEngine` string catalog through the same
  /// localization cascade as every other editor string (`LocalizationTable.localizedStringIfPresent(forKey:)`)
  /// — your app's main bundle first, so integrators can override — interpolating any `{{name}}`
  /// placeholders with the matching `args`, and falling back to the engine's English `message`
  /// when no copy is authored, so a surface never shows a blank or a raw `code`.
  ///
  /// Cast a thrown error with `EngineError(_:)` first; it is `nil` for errors from other domains,
  /// so keep your own fallback for those:
  ///
  /// ```swift
  /// builder.onError { error, eventHandler, _ in
  ///   let message = EngineError(error)?.displayMessage
  ///     ?? error.localizedDescription
  ///   present(message: message)
  /// }
  /// ```
  ///
  /// Mirrors the web `cesdk.i18n.localizedEngineErrorMessage(error)` resolver and the Android
  /// `EngineException.getDisplayMessage(context)` extension. The catalog id `SCENE.NOT_VALID`
  /// maps to the key `ly_img_engine_error_scene_not_valid`.
  var displayMessage: String {
    guard !code.isEmpty else { return message }
    let key = Self.errorMessageKey(for: code)
    if let localized = LocalizationTable.imglyEngine.localizedStringIfPresent(forKey: key), !localized.isEmpty {
      return localized.interpolatingEngineErrorArgs(args)
    }
    return message
  }

  /// The customer-facing body copy to display below ``displayMessage`` for this engine error, or
  /// `nil` when there is nothing to show.
  ///
  /// The longer-form companion to ``displayMessage``, mirroring the web resolver's `description`
  /// half and the engine's own message/hint split. It looks up the authored
  /// `ly_img_engine_error_<code>_description` string in the `IMGLYEngine` catalog through the same
  /// localization cascade — your app's main bundle first, so integrators can override —
  /// interpolating any `{{name}}` placeholders with the matching `args`, and falling back to the
  /// engine's English `hint` when no copy is authored. Returns `nil` when no copy is authored and
  /// the catalog declares no hint, so a surface can omit the line entirely instead of showing a
  /// blank.
  ///
  /// ```swift
  /// builder.onError { error, eventHandler, _ in
  ///   guard let engineError = EngineError(error) else { return }
  ///   present(title: engineError.displayMessage, body: engineError.displayDescription)
  /// }
  /// ```
  ///
  /// Mirrors the `description` returned by the web `cesdk.i18n.localizedEngineErrorMessage(error)`
  /// resolver and the Android `EngineException.getDisplayDescription(context)` extension. The
  /// catalog id `SCENE.NOT_VALID` maps to the key `ly_img_engine_error_scene_not_valid_description`.
  var displayDescription: String? {
    guard !code.isEmpty else { return hint.isEmpty ? nil : hint }
    let key = Self.errorMessageKey(for: code) + "_description"
    if let localized = LocalizationTable.imglyEngine.localizedStringIfPresent(forKey: key), !localized.isEmpty {
      return localized.interpolatingEngineErrorArgs(args)
    }
    return hint.isEmpty ? nil : hint
  }

  /// `SCENE.NOT_VALID` → `ly_img_engine_error_scene_not_valid`.
  private static func errorMessageKey(for code: String) -> String {
    "ly_img_engine_error_" + code.lowercased().replacingOccurrences(of: ".", with: "_")
  }
}

private extension String {
  /// Substitutes `{{name}}` placeholders in an authored override with the matching entry from the
  /// engine error's `args`, mirroring the Web `error.<code>` i18next interpolation so a single
  /// localized string covers every argument value. A placeholder with no matching arg is left
  /// intact, as the engine's own template rendering does. The engine `message`/`hint` fallbacks are
  /// already interpolated and never pass through here.
  func interpolatingEngineErrorArgs(_ args: [String: EngineError.ArgValue]) -> String {
    guard !args.isEmpty, contains("{{") else { return self }
    var result = self
    for (name, value) in args {
      result = result.replacingOccurrences(of: "{{\(name)}}", with: value.description)
    }
    return result
  }
}
