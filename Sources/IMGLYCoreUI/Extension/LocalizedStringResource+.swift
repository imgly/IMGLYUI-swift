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

@_spi(Internal) public struct LocalizationTable {
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
}

@_spi(Internal) public extension IMGLY where Wrapped == LocalizedStringResource {
  /// Creates a localized string resource with the same `keyAndValue` and performs localization
  /// ``lookup(table:bundle:locale:)`` at different locations.
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
  /// The resource for the first found localization for the provided `locale` is returned. The lookup is performed in
  /// the following order:
  /// 1. Default `"Localizable"` table in `.main` bundle.
  /// 2. Given `table` in `.main` bundle.
  /// 3. Given `table` in given `bundle`.
  /// - Parameters:
  ///   - table: The name of the table containing the key-value pairs. If `nil`, or an empty string, this value defaults
  /// to `"Localizable"`.
  ///   - bundle: The bundle that indicates where to locate the `table`’s strings file.
  ///   - locale: The locale for the resource to use.
  /// - Returns: The resolved localized string resource.
  func lookup(table: String?, bundle: Bundle, locale: Locale = .current) -> LocalizedStringResource {
    let notLocalized = LocalizedStringResource(
      wrapped.defaultValue, // Unfortunately, `wrapped.key` cannot be used as it is not exposed as a `StaticString`
      table: nil, // Assume there is no Localizable.xcstrings in IMGLYCoreUI
      locale: locale,
      bundle: .atURL(Bundle.module.bundleURL)
    )
    let notLocalizedString = String(localized: notLocalized)

    let mainLocalized = LocalizedStringResource(wrapped.defaultValue, table: nil, locale: locale, bundle: .main)
    let mainLocalizedString = String(localized: mainLocalized)
    if notLocalizedString != mainLocalizedString {
      return mainLocalized
    }

    let mainTableLocalized = LocalizedStringResource(wrapped.defaultValue, table: table, locale: locale, bundle: .main)
    let mainTableLocalizedString = String(localized: mainTableLocalized)
    if notLocalizedString != mainTableLocalizedString {
      return mainTableLocalized
    }

    let bundle = LocalizedStringResource.BundleDescription.atURL(bundle.bundleURL)
    let defaultLocalized = LocalizedStringResource(wrapped.defaultValue, table: table, locale: locale, bundle: bundle)
    let defaultLocalizedString = String(localized: defaultLocalized)
    if notLocalizedString == defaultLocalizedString {
      print("WARNING: Found unlocalized string resource: \(wrapped).")
    }
    return defaultLocalized
  }
}
