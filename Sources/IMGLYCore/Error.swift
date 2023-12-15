import Foundation

@_spi(Internal) public struct Error: LocalizedError {
  @_spi(Internal) public let errorDescription: String?

  @_spi(Internal) public init(errorDescription: String?) {
    self.errorDescription = errorDescription
  }
}
