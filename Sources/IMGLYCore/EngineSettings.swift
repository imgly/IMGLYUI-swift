import Foundation

/// Basic configuration settings to initialize the engine.
public struct EngineSettings: Sendable {
  @_spi(Internal) public let license: String?
  @_spi(Internal) public let userID: String?
  @_spi(Internal) public let baseURL: URL

  /// Creates engine settings.
  /// - Parameters:
  ///   - license: The license to activate the engine with. Pass `nil` to run the SDK in evaluation mode with a
  /// watermark.
  ///   - userID: An optional unique ID tied to your application's user. This helps us accurately calculate monthly
  /// active users (MAU). Especially useful when one person uses the app on multiple devices with a sign-in feature,
  /// ensuring they're counted once. Providing this aids in better data accuracy.
  ///   - baseURL: It is used to initialize the engine's `basePath` setting before the editor's `onCreate` callback is
  /// run. It is the foundational URL for constructing absolute paths from relative ones. This URL enables the loading
  /// of specific scenes or assets using their relative paths.
  public init(
    license: String? = nil,
    userID: String? = nil,
    baseURL: URL = .init(string: "https://cdn.img.ly/packages/imgly/cesdk-engine/1.66.0-rc.0/assets")!
  ) {
    self.license = license
    self.userID = userID
    self.baseURL = baseURL
  }
}
