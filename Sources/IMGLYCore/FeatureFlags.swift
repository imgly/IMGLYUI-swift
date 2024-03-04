import Foundation

@_spi(Internal) public enum FeatureFlags {
  @_spi(Internal) public static let designEditor: Bool = ProcessInfo.isUITesting
  @_spi(Internal) public static let sceneUpload: Bool = false
}
