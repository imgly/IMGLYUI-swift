import Foundation

@_spi(Internal) public enum PreviewServerRequest: String, Sendable {
  case secrets
  case resource

  @_spi(Internal) public static let defaultPort: UInt16 = 8080

  @_spi(Internal) public static func baseURL(port: UInt16 = defaultPort) -> URLComponents {
    var components = URLComponents()
    components.scheme = "http"
    components.host = "localhost"
    components.port = Int(port)
    return components
  }

  @_spi(Internal) public func url(port: UInt16 = defaultPort, path: String? = nil) -> URL {
    var components = Self.baseURL(port: port)
    components.path = "/\(rawValue)"
    if let path {
      components.path.append("/\(path)")
    }
    return components.url!
  }
}
