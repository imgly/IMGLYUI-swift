import AVFoundation
@_spi(Internal) import IMGLYCore
import IMGLYEngine
import UIKit

@_spi(Internal) public struct AssetUploadResult {
  let url: URL
  let blockType: DesignBlockType
  let blockKind: BlockKind
  let fillType: FillType?

  init(url: URL, blockType: DesignBlockType, blockKind: BlockKind, fillType: FillType? = nil) {
    self.url = url
    self.blockType = blockType
    self.blockKind = blockKind
    self.fillType = fillType
  }
}

@MainActor
@_spi(Internal) public protocol AssetLibraryInteractor: ObservableObject {
  var isAddingAsset: Bool { get }
  func findAssets(sourceID: String, query: AssetQueryData) async throws -> AssetQueryResult
  func getGroups(sourceID: String) async throws -> [String]
  func getCredits(sourceID: String) -> AssetCredits?
  func getLicense(sourceID: String) -> AssetLicense?
  func addAsset(to sourceID: String, asset: AssetDefinition) async throws -> AssetDefinition

  func uploadAsset(to sourceID: String, asset: AssetUpload) async throws -> AssetResult
  func assetTapped(sourceID: String, asset: AssetResult)

  typealias AssetUpload = () throws -> AssetUploadResult
}

@_spi(Internal) public extension AssetLibraryInteractor {
  func uploadImage(to sourceID: String, url: () throws -> URL) async throws -> AssetResult {
    try await uploadAsset(to: sourceID) {
      try .init(url: url(), blockType: .graphic, blockKind: .key(.image), fillType: .image)
    }
  }

  func uploadVideo(to sourceID: String, url: () throws -> URL) async throws -> AssetResult {
    try await uploadAsset(to: sourceID) {
      try .init(url: url(), blockType: .graphic, blockKind: .key(.video), fillType: .video)
    }
  }

  func uploadAudio(to sourceID: String, url: () throws -> URL) async throws -> AssetResult {
    try await uploadAsset(to: sourceID) {
      try .init(url: url(), blockType: .audio, blockKind: .key(.audio))
    }
  }

  func uploadAsset(to sourceID: String, asset: AssetUpload) async throws -> AssetResult {
    try await Self.uploadAsset(interactor: self, to: sourceID, asset: asset)
  }

  static func uploadAsset(interactor: any AssetLibraryInteractor,
                          to sourceID: String, asset: AssetUpload) async throws -> AssetResult {
    let assetResult = try asset()
    let meta = try await getMeta(url: assetResult.url, blockKind: assetResult.blockKind, fillType: assetResult.fillType)

    // Use `assetID` from return value because the id could have been changed in `addAsset`/`onUpload`.
    let assetID = try await interactor.addAsset(
      to: sourceID,
      asset: .init(id: assetResult.url.absoluteString, meta: meta),
    ).id

    let result = try await interactor.findAssets(
      sourceID: sourceID,
      query: .init(query: assetID, page: 0, perPage: 10),
    )
    guard result.assets.count == 1, let asset = result.assets.first else {
      throw Error(errorDescription: "Could not retrieve uploaded asset.")
    }
    NotificationCenter.default.post(name: .AssetSourceDidChange, object: nil, userInfo: ["sourceID": sourceID])

    return asset
  }
}

private struct SendableAVMetadataItem: @unchecked Sendable {
  let value: AVMetadataItem?

  init(_ value: AVMetadataItem?) {
    self.value = value
  }
}

private func getMeta(url: URL, thumbURL: URL? = nil, blockKind: BlockKind,
                     fillType: FillType? = nil) async throws -> AssetMeta {
  switch blockKind {
  case .key(.image), .key(.video):
    guard let fillType else {
      throw Error(errorDescription: "Could not retrieve `fillType` of uploaded asset.")
    }
    let (size, thumbURL) = try await getSizeAndThumb(url: url, thumbURL: thumbURL, fillType: fillType)
    let meta: AssetMeta = [
      .uri: url.absoluteString,
      .thumbUri: thumbURL.absoluteString,
      .kind: blockKind.rawValue,
      .width: String(Int(size.width)),
      .height: String(Int(size.height)),
      .blockType: DesignBlockType.graphic.rawValue,
      .fillType: fillType.rawValue,
    ]
    return meta

  case .key(.audio):
    let asset = AVURLAsset(url: url)
    let (duration, metadata) = try await asset.load(.duration, .commonMetadata)

    var meta: AssetMeta = [
      .uri: url.absoluteString,
      .blockType: DesignBlockType.audio.rawValue,
      .kind: blockKind.rawValue,
      .duration: String(duration.seconds),
    ]

    func parse(key: AVMetadataKey) -> SendableAVMetadataItem {
      .init(AVMetadataItem.metadataItems(from: metadata, withKey: key, keySpace: AVMetadataKeySpace.common).first)
    }

    let titleItem = parse(key: .commonKeyTitle)
    let artistItem = parse(key: .commonKeyArtist)
    let artworkItem = parse(key: .commonKeyArtwork)

    async let loadTitle = titleItem.value?.load(.stringValue)
    async let loadArtist = artistItem.value?.load(.stringValue)
    async let loadArtwork = artworkItem.value?.load(.dataValue)

    let (title, artist, artwork) = try await (loadTitle, loadArtist, loadArtwork)

    if let title {
      meta[.title] = title
    }
    if let artist {
      meta[.artist] = artist
    }
    if let artwork, let image = UIImage(data: artwork) {
      let data = image.jpegData(compressionQuality: 1)
      guard let data else {
        throw Error(errorDescription: "Could not save artwork thumbnail to data.")
      }
      let thumbURL = try data.writeToUniqueCacheURL(for: .jpeg)
      meta[.thumbUri] = thumbURL.absoluteString
    }
    return meta

  default:
    throw Error(errorDescription: "Unsupported block type for upload.")
  }
}

private func getSizeAndThumb(url: URL, thumbURL: URL?, fillType: FillType) async throws -> (CGSize, URL) {
  switch fillType {
  case .image:
    let (data, _) = try await URLSession.shared.data(from: url)
    guard let image = UIImage(data: data) else {
      throw Error(errorDescription: "Unsupported image data.")
    }
    return (image.size, thumbURL ?? url)

  case .video:
    let asset = AVURLAsset(url: url)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    let result = try await imageGenerator.image(at: .zero)
    let image = UIImage(cgImage: result.image)
    if let thumbURL {
      return (image.size, thumbURL)
    } else {
      let data = image.jpegData(compressionQuality: 1)
      guard let data else {
        throw Error(errorDescription: "Could not save video thumbnail to data.")
      }
      let thumbURL = try data.writeToUniqueCacheURL(for: .jpeg)
      return (image.size, thumbURL)
    }

  default:
    throw Error(errorDescription: "Unsupported block type for upload.")
  }
}

// MARK: - PhotoRoll

@_spi(Internal) public extension AssetLibraryInteractor {
  var isPhotoRollFullLibraryAccessEnabled: Bool {
    getCredits(sourceID: PhotoRollAssetSource.id)?.photoRollAssetSourceMode == .fullLibraryAccess
  }
}
