import Foundation
import IMGLYEngine

/// The typeface of a text block that a paste creates, as the web editor picks it, so formatted text keeps its bold and
/// italic: the typeface that the copy names, if the scene has it, then the family of most text presets, then the first
/// typeface of the library. Each of the last two needs a regular, a bold and an italic font.
enum PastedTextTypeface {
  private static let textPresetSourceID = "ly.img.text"
  private static let typefaceSourceID = "ly.img.typeface"
  private static let pageSize = 100

  @MainActor
  static func find(engine: Engine, html: String) async -> Typeface? {
    if let name = typefaceName(in: html) {
      for text in (try? engine.block.find(byType: .text)) ?? [] {
        if let typeface = try? engine.block.getTypefaces(text).first(where: { $0.name == name }) {
          return typeface
        }
      }
    }
    let sources = engine.asset.findAllSources()
    if sources.contains(textPresetSourceID), let typeface = await typefaceOfTextPresets(engine: engine),
       hasRegularBoldAndItalic(typeface) {
      return typeface
    }
    guard sources.contains(typefaceSourceID) else { return nil }
    var page = 0
    while let result = try? await engine.asset.findAssets(
      sourceID: typefaceSourceID,
      query: .init(query: nil, page: page, perPage: pageSize),
    ) {
      if let typeface = result.assets.lazy.compactMap(\.payload?.typeface).first(where: hasRegularBoldAndItalic) {
        return typeface
      }
      guard result.nextPage > page else { return nil }
      page = result.nextPage
    }
    return nil
  }

  /// The value of `data-cesdk-typeface`, which the engine writes in the HTML of a copied text.
  static func typefaceName(in html: String) -> String? {
    guard let range = html.range(of: "data-cesdk-typeface=\"") else { return nil }
    guard let end = html[range.upperBound...].firstIndex(of: "\"") else { return nil }
    return String(html[range.upperBound ..< end])
      .replacingOccurrences(of: "&quot;", with: "\"")
      .replacingOccurrences(of: "&lt;", with: "<")
      .replacingOccurrences(of: "&gt;", with: ">")
      .replacingOccurrences(of: "&amp;", with: "&")
  }

  @MainActor
  private static func typefaceOfTextPresets(engine: Engine) async -> Typeface? {
    guard let result = try? await engine.asset.findAssets(
      sourceID: textPresetSourceID,
      query: .init(query: nil, page: 0, perPage: pageSize),
    ) else { return nil }
    var presetsByFamily: [String: [AssetResult]] = [:]
    var families: [String] = []
    for asset in result.assets {
      guard let preset = asset.payload?.stylePreset.flatMap({ $0.data(using: .utf8) }),
            let json = try? JSONSerialization.jsonObject(with: preset) as? [String: Any],
            (json["blockType"] as? String ?? DesignBlockType.text.rawValue) == DesignBlockType.text.rawValue,
            let family = (json["typeface"] as? [String: Any])?["family"] as? String else { continue }
      if presetsByFamily[family] == nil {
        families.append(family)
      }
      presetsByFamily[family, default: []].append(asset)
    }
    // The first family with the most presets, as the web editor's reduce keeps the first maximum.
    guard let family = families.max(by: { presetsByFamily[$0]!.count < presetsByFamily[$1]!.count }),
          let preset = presetsByFamily[family]?.first else { return nil }
    guard let scratch = try? engine.block.create(.text) else { return nil }
    defer { try? engine.block.destroy(scratch) }
    do {
      try await engine.asset.applyToBlock(sourceID: textPresetSourceID, assetResult: preset, block: scratch)
      return try engine.block.getTypeface(scratch)
    } catch {
      return nil
    }
  }

  private static func hasRegularBoldAndItalic(_ typeface: Typeface) -> Bool {
    func has(_ weight: FontWeight, _ style: FontStyle) -> Bool {
      typeface.fonts.contains { $0.weight == weight && $0.style == style }
    }
    return has(.normal, .normal) && has(.bold, .normal) && has(.normal, .italic)
  }
}
