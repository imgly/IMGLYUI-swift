import Foundation

@_spi(Internal) public protocol IdentifiableByHash: Hashable, Identifiable {}

@_spi(Internal) public extension IdentifiableByHash {
  var id: Int { hashValue }
}
