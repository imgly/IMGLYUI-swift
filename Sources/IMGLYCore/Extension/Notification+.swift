import Foundation

@_spi(Internal) public extension Notification.Name {
  static let AssetSourceDidChange = Notification.Name("AssetSourceDidChange")
  static let PhotoRollImportStarted = Notification.Name("PhotoRollImportStarted")
  static let PhotoRollImportCompleted = Notification.Name("PhotoRollImportCompleted")
}
