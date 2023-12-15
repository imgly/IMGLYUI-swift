import Foundation
import IMGLYEngine

public final class TextAssetSource: NSObject {
  private let assets: [AssetResult] = [
    createAsset(id: "title", label: "Title", fontWeight: 700, fontSize: 32),
    createAsset(id: "headline", label: "Headline", fontWeight: 500, fontSize: 18),
    createAsset(id: "body", label: "Body", fontWeight: 400, fontSize: 14)
  ]

  weak var engine: Engine?

  public init(engine: Engine) {
    self.engine = engine
  }

  private static let basePath = URL(string: "/extensions/ly.img.cesdk.fonts")!
  private static let fontPath = [
    700: "fonts/Roboto/Roboto-Bold.ttf",
    500: "fonts/Roboto/Roboto-Medium.ttf",
    400: "fonts/Roboto/Roboto-Regular.ttf"
  ]
  private static func uri(fontWeight: Int) -> String? {
    guard let fontPath = fontPath[fontWeight] else {
      return nil
    }
    let fontURL = basePath.appendingPathComponent(fontPath, isDirectory: false)
    return fontURL.absoluteString
  }

  private static func createAsset(id: String, label: String, fontWeight: Int, fontSize: Int) -> AssetResult {
    .init(id: id,
          locale: "en",
          label: label,
          meta: [
            "uri": uri(fontWeight: fontWeight)!,
            "fontFamily": "Roboto",
            "fontWeight": String(fontWeight),
            "fontSize": String(fontSize),
            "blockType": DesignBlockType.text.rawValue
          ],
          context: .init(sourceID: Self.id))
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

  public func apply(asset: AssetResult) async throws -> NSNumber? {
    guard let engine, let id = try await engine.asset.defaultApplyAsset(assetResult: asset) else {
      return nil
    }

    try await engine.block.setString(id, property: "text/text", value: "Text")
    if let fontSize = asset.fontSize {
      let fontSize = (50.0 / 24.0) * Float(fontSize) // Scale font size to match scene.
      try await engine.block.setFloat(id, property: "text/fontSize", value: fontSize)
    }
    try await engine.block.setEnum(id, property: "text/horizontalAlignment", value: "Center")
    try await engine.block.setHeightMode(id, mode: .auto)

    return .init(value: id)
  }

  public var supportedMIMETypes: [String]? { nil }

  public var credits: AssetCredits? { nil }

  public var license: AssetLicense? { nil }
}
