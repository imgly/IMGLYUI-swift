import Foundation

public extension Locale {
  /// The current device language code (e.g., `"en"`, `"de"`), falling back to `"en"` if unavailable.
  static var currentLanguageCode: String {
    Locale.current.language.languageCode?.identifier ?? "en"
  }
}
