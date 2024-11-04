import Foundation

@_spi(Internal) public extension FileManager {
  func getUniqueCacheURL() throws -> URL {
    try url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
      .appendingPathComponent(UUID().uuidString)
  }

  func moveOrCopyItem(at source: URL, to destination: URL) throws {
    do {
      try moveItem(at: source, to: destination)
    } catch {
      try copyItem(at: source, to: destination)
    }
  }
}
