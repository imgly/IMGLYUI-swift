import Foundation
import IMGLYEngine

/// A custom asset source that provides access to the device's photo library.
/// This asset source allows users to browse and select images and videos from their photo library.
public class PhotoRollAssetSource: NSObject {
  private weak var engine: Engine?
  private let assetService = PhotoRollAssetService.default

  /// Creates a photo roll asset source.
  /// - Parameter engine: The engine instance used for asset operations.
  public init(engine: Engine) {
    self.engine = engine
    super.init()
  }
}

// MARK: - AssetSource

extension PhotoRollAssetSource: AssetSource {
  public static let id = "ly.img.asset.source.photoRoll"

  public nonisolated var id: String {
    Self.id
  }

  public nonisolated var supportedMIMETypes: [String]? {
    [MIMEType.jpeg.rawValue, MIMEType.png.rawValue, MIMEType.mp4.rawValue]
  }

  public nonisolated var credits: AssetCredits? {
    nil
  }

  public nonisolated var license: AssetLicense? {
    nil
  }

  @_spi(Internal) public static func refreshAssets() {
    NotificationCenter.default.post(name: .AssetSourceDidChange, object: nil, userInfo: ["sourceID": id])
  }

  public func findAssets(queryData: AssetQueryData) async throws -> AssetQueryResult {
    try await assetService.findAssets(queryData: queryData, sourceID: Self.id)
  }

  public func apply(asset: AssetResult) async throws -> NSNumber? {
    let updatedAsset = try await assetService.applyAsset(asset)
    guard let id = try await engine?.asset.defaultApplyAsset(assetResult: updatedAsset) else {
      return nil
    }
    return .init(value: id)
  }

  public func applyToBlock(asset: AssetResult, block: DesignBlockID) async throws {
    let updatedAsset = try await assetService.applyAsset(asset)
    try await engine?.asset.defaultApplyAssetToBlock(assetResult: updatedAsset, block: block)
  }

  public func getGroups() async throws -> [String] {
    PhotoRollMediaType.allCases.map(\.rawValue)
  }
}
