import Foundation

/// Basic configuration settings to initialize the engine.
public struct EngineSettings: Sendable {
  @_spi(Internal) public let license: String?
  @_spi(Internal) public let userID: String?
  @_spi(Internal) public let baseURL: URL
  @_spi(Internal) public let host: String

  /// Creates engine settings.
  /// - Parameters:
  ///   - license: The license to activate the engine with. Pass `nil` to run the SDK in evaluation mode with a
  /// watermark.
  ///   - userID: An optional unique ID tied to your application's user. This helps us accurately calculate monthly
  /// active users (MAU). Especially useful when one person uses the app on multiple devices with a sign-in feature,
  /// ensuring they're counted once. Providing this aids in better data accuracy.
  ///   - baseURL: It is used to initialize the engine's `basePath` setting before the editor's `onCreate` callback is
  /// run. It is the foundational URL for constructing absolute paths from relative ones. This URL enables the loading
  /// of specific scenes or assets using their relative paths. Pass `nil` to use the default public IMG.LY CDN, which
  /// is intended for evaluation and demos only; for production, point it at self-hosted or app-bundled assets.
  ///   - host: The integration context embedding the engine, used for license matching.
  public init(
    license: String? = nil,
    userID: String? = nil,
    baseURL: URL? = nil,
    host: String = ""
  ) {
    self.license = license
    self.userID = userID
    self.baseURL = baseURL ?? Self.defaultBaseURL
    self.host = host
  }

  /// The default base URL used when no `baseURL` is provided: the public CE.SDK CDN.
  private static let defaultBaseURL =
    URL(string: "https://cdn.img.ly/packages/imgly/cesdk-swift/1.78.0-rc.1/assets")!
}
