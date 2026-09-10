import Foundation
import IMGLYEngine
@preconcurrency import Photos

@_spi(Internal) public actor PhotoRollAssetService {
  @_spi(Internal) public static let `default` = PhotoRollAssetService()

  private let maxCacheSize: Int
  private let thumbnailTargetSize: CGSize
  private let photoLibraryService = PhotoLibraryService()

  private var assetResultCacheStorage = [String: AssetResult]()
  private var assetResultCacheOrder = [String]()

  /// Storage for uploaded assets when in photos picker mode (opted-out)
  private nonisolated(unsafe) var uploadedAssets: [AssetDefinition] = []

  @_spi(Internal) public init(
    maxCacheSize: Int = 500,
    thumbnailTargetSize: CGSize = .init(width: 250, height: 250)
  ) {
    self.maxCacheSize = maxCacheSize
    self.thumbnailTargetSize = thumbnailTargetSize
  }

  /// Add an uploaded asset to storage (for photos picker mode)
  @_spi(Internal) public nonisolated func addUploadedAsset(_ asset: AssetDefinition) {
    uploadedAssets.append(asset)
  }

  @_spi(Internal) public func saveMediaAndConvert(url: URL, mediaType: PHAssetMediaType) async throws -> AssetResult {
    let savedAsset = try await photoLibraryService.saveMediaAndFetch(url: url, mediaType: mediaType)
    return try await convertToAssetResult(savedAsset)
  }

  @_spi(Internal) public func findAssets(
    queryData: AssetQueryData,
    mode: PhotoRollAssetSourceMode,
  ) async throws -> AssetQueryResult {
    // If photos picker mode, return uploaded assets instead of PHAssets
    if mode == .photosPicker {
      return await findUploadedAssets(queryData: queryData)
    }

    // Full photo library mode - return PHAssets
    let authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    guard authorizationStatus == .authorized || authorizationStatus == .limited else {
      return AssetQueryResult(
        assets: [],
        currentPage: queryData.page,
        nextPage: -1,
        total: 0,
      )
    }

    var mediaTypes: Set<PhotoRollMediaType>?
    if let groups = queryData.groups {
      mediaTypes = PhotoRollMediaType.from(strings: groups)
    }

    let assets = await photoLibraryService.fetchAssets(mediaTypes: mediaTypes?.map(\.phAssetMediaType))

    if assets.count == 0 {
      return AssetQueryResult(
        assets: [],
        currentPage: queryData.page,
        nextPage: -1,
        total: 0,
      )
    }

    let totalCount = assets.count
    let page = queryData.page
    let perPage = queryData.perPage
    let totalPages = Int(ceil(Double(totalCount) / Double(perPage)))
    let nextPage = (page + 1) >= totalPages ? -1 : page + 1

    let startIndex = page * perPage
    let endIndex = min(startIndex + perPage, assets.count)

    let assetSubset = assets.objects(at: IndexSet(integersIn: startIndex ..< endIndex))
    let assetResults = try await assetSubset.concurrentMap { asset in
      try await self.convertToAssetResult(asset)
    }

    return AssetQueryResult(
      assets: assetResults,
      currentPage: page,
      nextPage: nextPage,
      total: totalCount,
    )
  }

  @_spi(Internal) public func applyAsset(_ asset: AssetResult) async throws -> AssetResult {
    if asset.url != nil {
      // Asset already imported with valid URL
      return asset
    }

    await MainActor.run {
      NotificationCenter.default.post(name: .PhotoRollImportStarted, object: nil)
    }

    do {
      let phAsset = try await photoLibraryService.fetchAsset(withIdentifier: asset.id)
      let assetURL = try await photoLibraryService.getAssetURL(phAsset)

      var updatedMeta = asset.meta ?? [:]
      updatedMeta["uri"] = assetURL.absoluteString

      let updatedAsset = AssetResult(
        id: asset.id,
        locale: asset.locale,
        label: asset.label,
        tags: asset.tags,
        meta: updatedMeta,
        payload: asset.payload,
        context: asset.context,
      )

      updateCacheWithURI(assetID: asset.id, uri: assetURL.absoluteString)

      await MainActor.run {
        NotificationCenter.default.post(name: .PhotoRollImportCompleted, object: nil)
      }

      return updatedAsset
    } catch {
      await MainActor.run {
        NotificationCenter.default.post(name: .PhotoRollImportCompleted, object: nil, userInfo: ["error": error])
      }
      throw error
    }
  }

  private func convertToAssetResult(_ phAsset: PHAsset) async throws -> AssetResult {
    if let cachedResult = assetResultCacheStorage[phAsset.localIdentifier] {
      return cachedResult
    }

    let thumbnailURL = try await photoLibraryService.getThumbnailURL(phAsset, targetSize: thumbnailTargetSize)

    var meta = [
      "thumbUri": thumbnailURL.absoluteString,
      "blockType": DesignBlockType.graphic.rawValue,
      "fillType": phAsset.mediaType == .image ? FillType.image.rawValue : FillType.video.rawValue,
      "shapeType": ShapeType.rect.rawValue,
      "kind": phAsset.mediaType == .image ? "image" : "video",
      "width": phAsset.pixelWidth.description,
      "height": phAsset.pixelHeight.description,
      "looping": "false",
    ]

    if phAsset.mediaType == .video {
      meta["duration"] = phAsset.duration.description
    }

    let creationDate = phAsset.creationDate ?? Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium

    let result = AssetResult(
      id: phAsset.localIdentifier,
      locale: "en",
      label: "\(phAsset.mediaType == .image ? "Photo" : "Video") from \(dateFormatter.string(from: creationDate))",
      meta: meta,
      context: .init(sourceID: PhotoRollAssetSource.id),
    )

    addAssetResultToCache(result, with: phAsset.localIdentifier)

    return result
  }

  private func updateCacheWithURI(assetID: String, uri: String) {
    guard let cachedResult = assetResultCacheStorage[assetID] else { return }

    var updatedMeta = cachedResult.meta ?? [:]
    updatedMeta["uri"] = uri

    assetResultCacheStorage[assetID] = AssetResult(
      id: cachedResult.id,
      locale: cachedResult.locale,
      label: cachedResult.label,
      tags: cachedResult.tags,
      meta: updatedMeta,
      payload: cachedResult.payload,
      context: cachedResult.context,
    )
  }

  private func addAssetResultToCache(_ assetResult: AssetResult, with key: String) {
    if assetResultCacheStorage[key] == nil {
      assetResultCacheOrder.append(key)
    }
    assetResultCacheStorage[key] = assetResult

    if assetResultCacheStorage.count > maxCacheSize, let oldest = assetResultCacheOrder.first {
      assetResultCacheStorage.removeValue(forKey: oldest)
      assetResultCacheOrder.removeFirst()
    }
  }

  // Return uploaded assets when in photos picker mode (opted-out)
  private func findUploadedAssets(queryData: AssetQueryData) async -> AssetQueryResult {
    var assets = [AssetDefinition]()
    var totalCount = 0

    // If querying for a specific asset by ID, don't filter by media type.
    // This is used by the upload flow (AssetLibraryInteractor.uploadAsset) which adds an asset
    // and immediately retrieves it using findAssets with the asset ID as the query parameter.
    if let query = queryData.query, !query.isEmpty {
      if let uploadedAsset = uploadedAssets.first(where: { $0.id == query }) {
        assets.append(uploadedAsset)
      }
      totalCount = assets.count
    } else {
      // Filter by media types if groups are specified
      var filteredAssets = uploadedAssets
      if let groups = queryData.groups {
        let mediaTypes = PhotoRollMediaType.from(strings: groups)
        filteredAssets = uploadedAssets.filter { asset in
          guard let kind = asset.meta?["kind"] else { return false }
          return mediaTypes.contains { $0.rawValue == kind }
        }
      }

      totalCount = filteredAssets.count

      // Apply pagination
      let page = queryData.page
      let perPage = queryData.perPage
      let startIndex = page * perPage
      let endIndex = min(startIndex + perPage, totalCount)

      assets = startIndex < filteredAssets.count ? Array(filteredAssets[startIndex ..< endIndex]) : []
    }

    let page = queryData.page
    let perPage = queryData.perPage
    let totalPages = totalCount > 0 ? Int(ceil(Double(totalCount) / Double(perPage))) : 0
    let nextPage = (page + 1) >= totalPages ? -1 : page + 1

    // Convert AssetDefinition to AssetResult
    let assetResults = assets.map { definition -> AssetResult in
      AssetResult(
        id: definition.id,
        meta: definition.meta,
        context: .init(sourceID: PhotoRollAssetSource.id),
      )
    }

    return AssetQueryResult(
      assets: assetResults,
      currentPage: page,
      nextPage: nextPage,
      total: totalCount,
    )
  }
}
