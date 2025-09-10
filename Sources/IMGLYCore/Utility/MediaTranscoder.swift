import AVFoundation
import Foundation
import UIKit
import UniformTypeIdentifiers

@_spi(Internal) public enum MediaTranscoder {
  // MARK: - Image Transcoding

  /// Transcode image data to JPEG format
  @_spi(Internal) public static func transcodeImageToJPEG(from imageData: Data) async throws -> URL {
    guard let image = UIImage(data: imageData) else {
      throw Error(errorDescription: "Could not load image for transcoding.")
    }
    guard let jpegData = image.jpegData(compressionQuality: 1.0) else {
      throw Error(errorDescription: "Could not save image for transcoding.")
    }
    return try jpegData.writeToUniqueCacheURL(for: .jpeg)
  }

  /// Process image data based on content type and transcoding preference
  @_spi(Internal) public static func processImage(data: Data, contentType: UTType,
                                                  shouldTranscode: Bool) async throws -> URL {
    if contentType != .jpeg, contentType != .png, shouldTranscode {
      try await transcodeImageToJPEG(from: data)
    } else {
      try data.writeToUniqueCacheURL(for: contentType)
    }
  }

  // MARK: - Video Transcoding

  /// Transcode video to MOV format using highest quality preset
  @_spi(Internal) public static func transcodeVideoToMOV(
    from avAsset: AVAsset,
    shouldOptimizeForNetwork: Bool = false,
  ) async throws -> URL {
    guard let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetHighestQuality) else {
      throw Error(errorDescription: "Could not create asset export session for transcoding.")
    }

    let outputURL = try FileManager.default.getUniqueCacheURL().appendingPathExtension(for: .quickTimeMovie)
    exportSession.outputURL = outputURL
    exportSession.outputFileType = .mov
    exportSession.shouldOptimizeForNetworkUse = shouldOptimizeForNetwork
    await exportSession.export()

    if let error = exportSession.error {
      throw error
    }

    return outputURL
  }

  /// Process video based on transcoding preference
  @_spi(Internal) public static func processVideo(
    avAsset: AVAsset,
    shouldTranscode: Bool,
    shouldOptimizeForNetwork: Bool = false,
  ) async throws -> URL {
    if shouldTranscode {
      return try await transcodeVideoToMOV(from: avAsset, shouldOptimizeForNetwork: shouldOptimizeForNetwork)
    } else {
      // For non-transcoded videos, copy to cache if it's a URL asset
      guard let urlAsset = avAsset as? AVURLAsset else {
        throw Error(errorDescription: "Could not load video.")
      }
      return try urlAsset.url.moveOrCopyToUniqueCacheURL()
    }
  }

  // MARK: - URL-based convenience methods

  /// Transcode image from URL to JPEG
  @_spi(Internal) public static func transcodeImageToJPEG(from url: URL) async throws -> URL {
    let (imageData, _) = try await URLSession.shared.data(from: url)
    return try await transcodeImageToJPEG(from: imageData)
  }

  /// Transcode video from URL to MOV
  @_spi(Internal) public static func transcodeVideoToMOV(from url: URL,
                                                         shouldOptimizeForNetwork: Bool = false) async throws -> URL {
    let avAsset = AVAsset(url: url)
    return try await transcodeVideoToMOV(from: avAsset, shouldOptimizeForNetwork: shouldOptimizeForNetwork)
  }
}
