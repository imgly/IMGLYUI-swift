import SwiftUI

@_spi(Internal) public protocol Localizable: CustomStringConvertible {}

@_spi(Internal) public extension Localizable {
  var localizedStringKey: LocalizedStringKey {
    localizedStringKey(suffix: nil)
  }

  func localizedStringKey(suffix: String?) -> LocalizedStringKey {
    LocalizedStringKey(String(describing: self) + (suffix ?? ""))
  }
}
