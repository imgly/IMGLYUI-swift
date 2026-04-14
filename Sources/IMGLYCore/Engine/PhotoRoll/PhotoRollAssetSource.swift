import Foundation
import IMGLYEngine

/// The mode for accessing the device's photo library.
public enum PhotoRollAssetSourceMode: CaseIterable, Sendable {
  /// Uses the system photos picker. No photo library permissions required.
  case photosPicker
  /// Enables full photo library access. Requires user permission on first use and `NSPhotoLibraryUsageDescription` in
  /// Info.plist.
  case fullLibraryAccess
}

@_spi(Internal) public extension PhotoRollAssetSourceMode {
  private var description: String {
    switch self {
    case .photosPicker: "photosPicker"
    case .fullLibraryAccess: "fullLibraryAccess"
    }
  }

  // Encode mode in credits so UI can determine which mode is active
  var assetCredits: AssetCredits {
    AssetCredits(name: description, url: nil)
  }
}

@_spi(Internal) public extension AssetCredits {
  var photoRollAssetSourceMode: PhotoRollAssetSourceMode? {
    switch name {
    case "photosPicker": .photosPicker
    case "fullLibraryAccess": .fullLibraryAccess
    default: nil
    }
  }
}

/// A custom asset source that provides access to the device's photo library.
/// This asset source allows users to browse and select images and videos from their photo library.
///
/// ## Usage
///
/// `PhotoRollAssetSource` is automatically registered by `OnCreate.loadAssetSources`.
/// By default, it operates in photos picker mode (no permissions required).
///
/// To enable full photo library access, override `loadAssetSources` in your configuration
/// and pass `.fullLibraryAccess` mode:
///
/// ```swift
/// .imgly.onCreate { engine in
///   // ... other setup
///   try engine.asset.addSource(PhotoRollAssetSource(engine: engine, mode: .fullLibraryAccess))
/// }
/// ```
///
/// ## Behavior
///
/// - **Photos Picker Mode** (default): Opens system photos picker, no permissions required
/// - **Full Library Access Mode**: Loads photo library into asset panel, requires permission on first use
public class PhotoRollAssetSource: NSObject {
  private weak var engine: Engine?
  private let mode: PhotoRollAssetSourceMode
  private let assetService = PhotoRollAssetService.default

  /// Creates a photo roll asset source.
  /// - Parameters:
  ///   - engine: The engine instance used for asset operations.
  ///   - mode: The mode used.
  @MainActor
  public init(engine: Engine, mode: PhotoRollAssetSourceMode = .photosPicker) {
    self.engine = engine
    self.mode = FeatureFlags.isEnabled(.photoRollOptIn) ? .fullLibraryAccess : mode
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
    mode.assetCredits
  }

  public nonisolated var license: AssetLicense? {
    nil
  }

  @_spi(Internal) public static func refreshAssets() {
    NotificationCenter.default.post(name: .AssetSourceDidChange, object: nil, userInfo: ["sourceID": id])
  }

  public func findAssets(queryData: AssetQueryData) async throws -> AssetQueryResult {
    try await assetService.findAssets(queryData: queryData, mode: mode)
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

  public func add(asset: AssetDefinition) throws {
    assetService.addUploadedAsset(asset)
    Self.refreshAssets()
  }
}
