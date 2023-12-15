import Foundation

@_spi(Internal) public extension FileManager {
  func getUniqueCacheURL() throws -> URL {
    try url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
      .appendingPathComponent(UUID().uuidString)
  }
}
