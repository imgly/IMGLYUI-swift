import Foundation

@_spi(Internal) public struct Secrets: Codable {
  @_spi(Internal) public let remoteAssetSourceHost: String
  @_spi(Internal) public let unsplashHost: String
  @_spi(Internal) public let ciBuildsHost: String
  @_spi(Internal) public let githubRepo: String
  @_spi(Internal) public let licenseKey: String
}
