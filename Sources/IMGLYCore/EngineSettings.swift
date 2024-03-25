import Foundation

public struct EngineSettings: Sendable {
  @_spi(Internal) public let license: String
  @_spi(Internal) public let userID: String?
  @_spi(Internal) public let baseURL: URL

  public init(
    license: String,
    userID: String? = nil,
    baseURL: URL = .init(string: "https://cdn.img.ly/packages/imgly/cesdk-engine/1.23.0-rc.3/assets")!
  ) {
    self.license = license
    self.userID = userID
    self.baseURL = baseURL
  }
}
