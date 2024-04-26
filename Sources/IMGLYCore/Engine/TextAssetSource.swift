import Foundation
import IMGLYEngine

public final class TextAssetSource: NSObject {
  private weak var engine: Engine?
  private let assets: [AssetResult]

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

  public init(engine: Engine, typeface: Typeface) throws {
    self.engine = engine
    assets = try [
      Self.createAsset(typeface, id: "title", label: "Title", fontWeight: .bold, fontSize: 32),
      Self.createAsset(typeface, id: "headline", label: "Headline", fontWeight: .medium, fontSize: 18),
      Self.createAsset(typeface, id: "body", label: "Body", fontWeight: .normal, fontSize: 14)
    ]
  }

  private static func createAsset(
    _ typeface: Typeface,
    id: String,
    label: String,
    fontWeight: FontWeight,
    fontSize: Int
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
        "blockType": DesignBlockType.text.rawValue
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

    try engine.block.setString(id, property: "text/text", value: "Text")
    if let fontSize = asset.fontSize {
      let fontSize = (50.0 / 24.0) * Float(fontSize) // Scale font size to match scene.
      try engine.block.setFloat(id, property: "text/fontSize", value: fontSize)
    }
    try engine.block.setEnum(id, property: "text/horizontalAlignment", value: "Center")
    try engine.block.setHeightMode(id, mode: .auto)

    return .init(value: id)
  }

  public var supportedMIMETypes: [String]? { nil }

  public var credits: AssetCredits? { nil }

  public var license: AssetLicense? { nil }
}
