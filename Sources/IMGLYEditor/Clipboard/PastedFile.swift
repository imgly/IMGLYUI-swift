import Foundation
@_spi(Internal) import IMGLYCore
import UIKit
import UniformTypeIdentifiers

/// A file of the clipboard that loads from its creation, because an item provider of the clipboard no longer loads
/// once the paste command has returned. It copies the file into the cache, as an upload from the file picker does,
/// because the provider deletes its file when the load ends.
final class PastedFile: @unchecked Sendable {
  private let lock = NSLock()
  private var result: Result<URL, Swift.Error>?
  private var waiting: [CheckedContinuation<URL, Swift.Error>] = []

  init(provider: NSItemProvider, type: UTType) {
    _ = provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { [self] url, error in
      finish(Result {
        guard let url else {
          throw error ?? CocoaError(.fileReadUnknown)
        }
        let copy = try FileManager.default.getUniqueCacheURL()
          .appendingPathExtension(type.preferredFilenameExtension ?? url.pathExtension)
        try FileManager.default.copyItem(at: url, to: copy)
        if type.conforms(to: .png) {
          try Self.convertAppleOptimizedPNG(at: copy)
        }
        return copy
      })
    }
  }

  /// Photos hands over a PNG in Apple's variant for iOS, with a `CgBI` chunk before `IHDR`, which only Apple's
  /// decoders read. Writes such a file as a standard PNG, otherwise the engine cannot decode the pasted image.
  static func convertAppleOptimizedPNG(at url: URL) throws {
    let handle = try FileHandle(forReadingFrom: url)
    let header = try handle.read(upToCount: 16) ?? Data()
    try handle.close()
    guard header.count == 16, header.suffix(4) == Data("CgBI".utf8) else { return }
    guard let png = UIImage(contentsOfFile: url.path)?.pngData() else { throw CocoaError(.fileReadCorruptFile) }
    try png.write(to: url)
  }

  /// The file in the cache, once it is there.
  var url: URL {
    get async throws {
      try await withCheckedThrowingContinuation { continuation in
        lock.lock()
        if let result {
          lock.unlock()
          continuation.resume(with: result)
        } else {
          waiting.append(continuation)
          lock.unlock()
        }
      }
    }
  }

  private func finish(_ result: Result<URL, Swift.Error>) {
    lock.lock()
    self.result = result
    let continuations = waiting
    waiting = []
    lock.unlock()
    continuations.forEach { $0.resume(with: result) }
  }
}
