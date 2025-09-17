import Foundation
import Photos

/// Represents the types of media that can be accessed from the photo roll.
public enum PhotoRollMediaType: String, CaseIterable, Hashable, Sendable {
  /// Image media type (photos).
  case image
  /// Video media type.
  case video

  @_spi(Internal) public var phAssetMediaType: PHAssetMediaType {
    switch self {
    case .image:
      .image
    case .video:
      .video
    }
  }

  @_spi(Internal) public static func from(strings: [String]) -> Set<PhotoRollMediaType> {
    Set(strings.compactMap(PhotoRollMediaType.init(rawValue:)))
  }
}
