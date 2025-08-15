import Foundation
import IMGLYEngine

/// A custom asset source that applies different font weight and size when applied to a text block.
public final class TextAssetSource: NSObject {
  private weak var engine: Engine?
  private let assets: [AssetResult]

  /// Creates a text asset source and fetches the used typeface from another asset source.
  /// - Parameters:
  ///   - engine: The used engine.
  ///   - typefaceName: The name of the typeface that should be used.
  ///   - typefaceSourceID: The asset source ID where the typeface should be fetched from.
  @MainActor
  public convenience init(
    engine: Engine,
    typefaceName: String = "Roboto",
    typefaceSourceID: String = Engine.DefaultAssetSource.typeface.rawValue
  ) async throws {
    guard let asset = try await engine.asset.findAssets(
      sourceID: typefaceSourceID,
      query: .init(query: typefaceName, page: 0, locale: "en", perPage: 1)
    ).assets.first, let typeface = asset.payload?.typeface, typeface.name == typefaceName else {
      throw Error(errorDescription: "Typeface \(typefaceName) not found in \(typefaceSourceID) asset source.")
    }
    try self.init(engine: engine, typeface: typeface)
  }

  /// Creates a text asset source with a typeface.
  /// - Parameters:
  ///   - engine: The used engine.
  ///   - typeface: The typeface that should be used when applying text asset.
  public init(engine: Engine, typeface: Typeface) throws {
    self.engine = engine
    assets = try [
      Self.createAsset(typeface, id: "title", label: "Title", fontWeight: .bold, fontSize: 32, fontScale: 4),
      Self.createAsset(typeface, id: "headline", label: "Headline", fontWeight: .medium, fontSize: 18, fontScale: 2.8),
      Self.createAsset(typeface, id: "body", label: "Body", fontWeight: .normal, fontSize: 14, fontScale: 2),
    ]
  }

  private static func createAsset(
    _ typeface: Typeface,
    id: String,
    label: String,
    fontWeight: FontWeight,
    fontSize: Int,
    fontScale: Double
  ) throws -> AssetResult {
    guard let uri = typeface.fonts.first(where: {
      $0.weight == fontWeight && $0.style == .normal
    })?.uri else {
      throw Error(errorDescription: "Typeface must support \(fontWeight) font weight.")
    }
    return .init(
      id: id,
      locale: "en",
      label: label,
      meta: [
        "uri": uri.absoluteString,
        "fontFamily": typeface.name,
        "fontWeight": String(fontWeight.rawValue),
        "fontSize": String(fontSize),
        "fontScale": String(fontScale),
        "blockType": DesignBlockType.text.rawValue,
      ],
      payload: .init(typeface: typeface),
      context: .init(sourceID: Self.id)
    )
  }
}

extension TextAssetSource: AssetSource {
  public static let id = "ly.img.asset.source.text"

  public var id: String { Self.id }

  public func findAssets(queryData: AssetQueryData) async throws -> AssetQueryResult {
    let query = queryData.query?.lowercased() ?? ""
    let filteredAssets = query.isEmpty ? assets : assets.filter {
      $0.id.lowercased().contains(query)
    }
    let totalPages = Int(ceil(Double(filteredAssets.count) / Double(queryData.perPage))) - 1
    let paginatedAssets = filteredAssets.dropFirst(queryData.page * queryData.perPage).prefix(queryData.perPage)
    return .init(
      assets: Array(paginatedAssets),
      currentPage: queryData.page,
      nextPage: queryData.page == totalPages ? -1 : queryData.page + 1,
      total: filteredAssets.count
    )
  }

  @MainActor
  public func apply(asset: AssetResult) async throws -> NSNumber? {
    guard let engine, let id = try await engine.asset.defaultApplyAsset(assetResult: asset) else {
      return nil
    }

    try engine.block.setString(id, property: "text/text", value: asset.label ?? "Text")
    try engine.block.setEnum(id, property: "text/horizontalAlignment", value: "Center")
    try engine.block.setHeightMode(id, mode: .auto)
    try engine.block.setWidthMode(id, mode: .absolute)
    try engine.block.setBool(id, property: "text/clipLinesOutsideOfFrame", value: false)

    return .init(value: id)
  }

  public var supportedMIMETypes: [String]? { nil }

  public var credits: AssetCredits? { nil }

  public var license: AssetLicense? { nil }
}
