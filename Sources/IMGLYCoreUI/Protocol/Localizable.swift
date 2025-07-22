import Foundation

@_spi(Internal) public protocol Localizable {
  var localizationValue: String.LocalizationValue { get }
  var localizationTable: LocalizationTable { get }
}

@_spi(Internal) public extension Localizable {
  var localizationTable: LocalizationTable { .imglyCoreUI }

  var localizedStringResource: LocalizedStringResource {
    .imgly.localized(localizationValue, table: localizationTable)
  }
}
