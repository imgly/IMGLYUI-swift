@preconcurrency import AVFoundation
import Foundation
import IMGLYEngine
@preconcurrency import Photos

actor PhotoLibraryService: NSObject {
  private let imageManager: PHImageManager = .default()
  private var isObserverRegistered = false
  private var currentFetchResult: PHFetchResult<PHAsset>?

  private var imageRequestOptions: PHImageRequestOptions {
    let options = PHImageRequestOptions()
    options.isNetworkAccessAllowed = true
    options.deliveryMode = .highQualityFormat
    options.isSynchronous = false
    options.version = .current
    return options
  }

  private var videoRequestOptions: PHVideoRequestOptions {
    let options = PHVideoRequestOptions()
    options.isNetworkAccessAllowed = true
    options.deliveryMode = .highQualityFormat
    options.version = .current
    return options
  }

  private var thumbnailImageRequestOptions: PHImageRequestOptions {
    let options = PHImageRequestOptions()
    options.isSynchronous = false
    options.deliveryMode = .highQualityFormat
    options.resizeMode = .exact
    options.isNetworkAccessAllowed = false
    return options
  }

  deinit {
    if isObserverRegistered {
      PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
  }

  func saveMediaAndFetch(url: URL, mediaType: PHAssetMediaType) async throws -> PHAsset {
    var assetIdentifier: String?

    try await PHPhotoLibrary.shared().performChanges {
      let creationRequest: PHAssetChangeRequest? = switch mediaType {
      case .image:
        PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
      case .video:
        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
      default:
        nil
      }

      assetIdentifier = creationRequest?.placeholderForCreatedAsset?.localIdentifier
    }

    guard let assetIdentifier else { throw Error(errorDescription: "Failed to save asset to photo library.") }

    return try fetchAsset(withIdentifier: assetIdentifier)
  }

  func fetchAssets(mediaTypes: [PHAssetMediaType]? = nil) -> PHFetchResult<PHAsset> {
    registerObserverIfNecessary()

    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [
      NSSortDescriptor(key: "creationDate", ascending: false),
    ]

    if let mediaTypes, !mediaTypes.isEmpty {
      let predicates = mediaTypes.map { mediaType in
        NSPredicate(format: "mediaType == %d", mediaType.rawValue)
      }
      fetchOptions.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
    }

    let result = PHAsset.fetchAssets(with: fetchOptions)
    currentFetchResult = result
    return result
  }

  func fetchAsset(withIdentifier identifier: String) throws -> PHAsset {
    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)

    guard let asset = fetchResult.firstObject else {
      throw Error(errorDescription: "Failed to load asset from photo library.")
    }

    return asset
  }

  func getAssetURL(_ asset: PHAsset) async throws -> URL {
    switch asset.mediaType {
    case .image:
      try await getImageAssetURL(asset)
    case .video:
      try await getVideoAssetURL(asset)
    default:
      throw Error(errorDescription: "Failed to load asset from photo library.")
    }
  }

  func getThumbnailURL(_ asset: PHAsset, targetSize: CGSize) async throws -> URL {
    let image = try await withCheckedThrowingContinuation { continuation in
      imageManager.requestImage(
        for: asset,
        targetSize: targetSize,
        contentMode: .aspectFill,
        options: thumbnailImageRequestOptions,
      ) { image, _ in
        if let image {
          continuation.resume(returning: image)
        } else {
          continuation.resume(throwing: Error(errorDescription: "Could not load thumbnail."))
        }
      }
    }

    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
      throw Error(errorDescription: "Could not create thumbnail data.")
    }

    return try imageData.writeToUniqueCacheURL(for: .jpeg)
  }

  private func registerObserverIfNecessary() {
    guard !isObserverRegistered else { return }

    isObserverRegistered = true
    PHPhotoLibrary.shared().register(self)
  }

  private func getImageAssetURL(_ asset: PHAsset) async throws -> URL {
    let (imageData, uti) = try await withCheckedThrowingContinuation { continuation in
      imageManager.requestImageDataAndOrientation(
        for: asset,
        options: imageRequestOptions,
      ) { imageData, dataUTI, _, _ in
        if let imageData {
          continuation.resume(returning: (imageData, dataUTI))
        } else {
          continuation.resume(throwing: Error(errorDescription: "Could not load image."))
        }
      }
    }

    let contentType = uti.contentType ?? .jpeg

    let shouldTranscode = await FeatureFlags.isEnabled(.transcodePickerImageImports)
    return try await MediaTranscoder.processImage(
      data: imageData,
      contentType: contentType,
      shouldTranscode: shouldTranscode,
    )
  }

  private func getVideoAssetURL(_ asset: PHAsset) async throws -> URL {
    let avAsset = try await withCheckedThrowingContinuation { continuation in
      imageManager.requestAVAsset(forVideo: asset, options: videoRequestOptions) { avAsset, _, _ in
        if let avAsset {
          continuation.resume(returning: avAsset)
        } else {
          continuation.resume(throwing: Error(errorDescription: "Could not load video."))
        }
      }
    }

    let shouldTranscode = await FeatureFlags.isEnabled(.transcodePickerVideoImports)
    return try await MediaTranscoder.processVideo(
      avAsset: avAsset,
      shouldTranscode: shouldTranscode,
      shouldOptimizeForNetwork: true,
    )
  }
}

extension PhotoLibraryService: PHPhotoLibraryChangeObserver {
  public nonisolated func photoLibraryDidChange(_ change: PHChange) {
    Task { [weak self] in
      guard let self, let currentResult = await currentFetchResult,
            let changeDetails = change.changeDetails(for: currentResult),
            changeDetails.hasIncrementalChanges || changeDetails.fetchResultAfterChanges != currentResult
      else { return }

      await updateCurrentFetchResult(with: changeDetails.fetchResultAfterChanges)
      await MainActor.run { PhotoRollAssetSource.refreshAssets() }
    }
  }

  private func updateCurrentFetchResult(with fetchResult: PHFetchResult<PHAsset>) {
    currentFetchResult = fetchResult
  }
}

private extension String? {
  var contentType: UTType? {
    guard let self else { return nil }
    return UTType(self)
  }
}
