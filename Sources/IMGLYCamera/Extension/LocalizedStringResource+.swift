import Foundation
@_spi(Internal) import IMGLYCoreUI

@_spi(Internal) public extension LocalizationTable {
  static let imglyCamera = LocalizationTable(table: "IMGLYCamera", bundle: .module)
}

extension IMGLY where Wrapped == LocalizedStringResource {
  static func localized(_ keyAndValue: String.LocalizationValue) -> Wrapped {
    .imgly.localized(keyAndValue, table: .imglyCamera)
  }
}
