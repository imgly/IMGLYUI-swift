import Foundation
import UniformTypeIdentifiers

@_spi(Internal) public extension Data {
  func writeToUniqueCacheURL(for contentType: UTType) throws -> URL {
    let url = try FileManager.default.getUniqueCacheURL().appendingPathExtension(for: contentType)
    try write(to: url)
    return url
  }
}
