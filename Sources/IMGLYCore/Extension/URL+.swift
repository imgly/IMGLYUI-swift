import Foundation

@_spi(Internal) public extension URL {
  func moveOrCopyToUniqueCacheURL() throws -> URL {
    let manager = FileManager.default
    let url = try manager.getUniqueCacheURL().appendingPathExtension(pathExtension)
    try manager.moveOrCopyItem(at: self, to: url)
    return url
  }
}
