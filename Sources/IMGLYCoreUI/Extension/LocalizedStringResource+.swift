import Foundation
@_spi(Internal) import IMGLYCore

extension LocalizedStringResource: IMGLYCompatible {}

public extension IMGLY where Wrapped == LocalizedStringResource {
  /// Creates a localized string resource with the same `keyAndValue` and performs localization lookup at different
  /// locations.
  ///
  /// The resource for the first found localization for the current locale is returned. The lookup is performed in the
  /// following order:
  /// 1. Default `"Localizable"` table in `.main` bundle.
  /// 2. `"IMGLYEditor"` table in `.main` bundle.
  /// 3. `"IMGLYEditor"` table in `IMGLYCoreUI` bundle.
  /// - Parameter keyAndValue: The key for an entry in the specified table.
  /// - Returns: The created localized string resource.
  static func localized(_ keyAndValue: String.LocalizationValue) -> Wrapped {
    .imgly.localized(keyAndValue, table: .imglyCoreUI)
  }
}

@_spi(Internal) public struct LocalizationTable: Sendable {
  let table: String?
  let bundle: Bundle

  @_spi(Internal) public init(table: String?, bundle: Bundle) {
    self.table = table
    self.bundle = bundle
  }
}

@_spi(Internal) public extension LocalizationTable {
  /// Yes, `IMGLYEditor.xcstrings` is defined in module IMGLYUI because IMGLYEditor module depends on IMGLYUI and we
  /// want to provide a single string catalog table for everything IMGLYEditor to the consumer and not split it into
  /// multiple string catalogs.
  static let imglyCoreUI = LocalizationTable(table: "IMGLYEditor", bundle: .module)

  /// Customer-facing engine error copy. Keyed `ly_img_engine_error_<code>` and generated from
  /// `mobile-errors.tsv`. Lives in its own `IMGLYEngine` catalog (separate from `IMGLYEditor`) so the
  /// copy team can author it on demand without touching the editor catalog, and the
  /// `ly_img_engine_` namespace cannot collide with editor keys.
  static let imglyEngine = LocalizationTable(table: "IMGLYEngine", bundle: .module)

  /// Resolves `key` through the standard CE.SDK localization cascade and returns the localized value,
  /// or `nil` when no localization is authored at any level. The lookup is performed in the following
  /// order (first match wins):
  /// 1. Default `"Localizable"` table in `.main` bundle.
  /// 2. ``table`` in `.main` bundle.
  /// 3. ``table`` in ``bundle``.
  ///
  /// Unlike resolving through `LocalizedStringResource`, this returns the value eagerly and is the
  /// shared primitive behind both ``lookup(table:bundle:)`` and the engine-error resolver.
  /// - Parameter key: The key for an entry in the cascade.
  /// - Returns: The first authored localization for the current locale, or `nil` if the key is absent.
  func localizedStringIfPresent(forKey key: String) -> String? {
    Bundle.main.localizedStringIfPresent(forKey: key, table: nil)
      ?? Bundle.main.localizedStringIfPresent(forKey: key, table: table)
      ?? bundle.localizedStringIfPresent(forKey: key, table: table)
  }
}

@_spi(Internal) public extension IMGLY where Wrapped == LocalizedStringResource {
  /// Creates a localized string resource with the same `keyAndValue` and performs localization
  /// ``lookup(table:bundle:)`` at different locations.
  /// - Parameters:
  ///   - keyAndValue: The key for an entry in the specified table.
  ///   - tableAndBundle: The name of the table and bundle containing the key-value pairs as last resort.
  /// - Returns: The created localized string resource.
  static func localized(_ keyAndValue: String.LocalizationValue, table tableAndBundle: LocalizationTable) -> Wrapped {
    .init(keyAndValue).imgly.lookup(table: tableAndBundle.table, bundle: tableAndBundle.bundle)
  }

  /// Resolves a localized string resource that was created with the same `keyAndValue` by performing localization
  /// lookup at different locations.
  ///
  /// The resource for the first found localization for the current locale is returned. The lookup is performed in the
  /// following order:
  /// 1. Default `"Localizable"` table in `.main` bundle.
  /// 2. Given `table` in `.main` bundle.
  /// 3. Given `table` in given `bundle`.
  /// - Parameters:
  ///   - table: The name of the table containing the key-value pairs. If `nil`, or an empty string, this value defaults
  /// to `"Localizable"`.
  ///   - bundle: The bundle that indicates where to locate the `table`’s strings file.
  /// - Returns: The resolved localized string resource.
  func lookup(table: String?, bundle: Bundle) -> LocalizedStringResource {
    // Detect presence eagerly but return a `LocalizedStringResource` pointing at the matched
    // location so SwiftUI can re-resolve it lazily when the locale changes.
    if Bundle.main.localizedStringIfPresent(forKey: wrapped.key, table: nil) != nil {
      return LocalizedStringResource(wrapped.defaultValue, table: nil, bundle: .main)
    }

    if Bundle.main.localizedStringIfPresent(forKey: wrapped.key, table: table) != nil {
      return LocalizedStringResource(wrapped.defaultValue, table: table, bundle: .main)
    }

    if bundle.localizedStringIfPresent(forKey: wrapped.key, table: table) == nil {
      print("WARNING: Found unlocalized string resource: \(wrapped).")
    }
    return LocalizedStringResource(wrapped.defaultValue, table: table, bundle: .atURL(bundle.bundleURL))
  }
}

private extension Bundle {
  /// Looks `key` up in `table` (or `"Localizable"` when `nil`) and returns the authored value, or
  /// `nil` when the key is absent. A `\u{0}` sentinel is used as the fallback value to detect a
  /// missing key, which—unlike the `resolved == key` trick—still treats copy authored identically to
  /// the key as found.
  ///
  /// Uses the 3-argument `localizedString(forKey:value:table:)`; don't switch to the
  /// `localizations:` overload, it is as slow as `String(localized:)`.
  func localizedStringIfPresent(forKey key: String, table: String?) -> String? {
    let sentinel = "\u{0}"
    let resolved = localizedString(forKey: key, value: sentinel, table: table)
    return resolved == sentinel ? nil : resolved
  }
}
