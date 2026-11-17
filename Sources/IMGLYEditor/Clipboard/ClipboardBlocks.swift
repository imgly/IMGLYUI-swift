import Foundation

/// The CE.SDK block format of the system clipboard, which the web editor writes and reads too: an HTML flavor whose
/// empty spans carry the blocks as `block.saveToString` wrote them and the bytes of each resource that only the
/// copying engine can load. `bindings/wasm/js_web/src/clipboard/cesdkBlocks.ts` defines it.
enum ClipboardBlocks {
  /// Bump when a paste can no longer read what an older copy wrote.
  static let version = "1"

  /// Resources with these schemes keep their URL. Every other scheme only resolves in the engine that copied, so the
  /// copy carries its bytes.
  static let portableSchemes = ["http", "https"]

  /// The schemes that the copy for this engine keeps as they are: a paste in this session loads them again.
  static let sessionSchemes = ["buffer", "blob", "bundle", "file", "http", "https", "opfs", "data"]

  /// The blocks name each carried resource by a URL with this prefix, unique to the copy, so the relocation after a
  /// paste moves no URL that the scene already uses.
  static let resourceURLPrefix = "buffer://ly.img.clipboard/"

  /// The bytes of resources that a copy carries at most, as in the web editor. Base64 makes this about 43 MB of HTML. A
  /// larger copy pastes only in the editor that copied.
  static let maxEmbeddedBytes = 32 * 1024 * 1024

  /// A resource that travels with the blocks.
  struct Resource: Equatable {
    let mimeType: String
    let data: Data
  }

  /// What a CE.SDK copy put on the clipboard.
  struct Payload: Equatable {
    /// The id of the copy, so the engine that copied can paste its session copy.
    let id: String
    /// The blocks as `block.saveToString` wrote them. Empty when the copy was too large to carry.
    let blocks: String
    /// The bytes of each carried resource, by the URL that the blocks name it with.
    let resources: [String: Resource]
  }

  static func placeholder(copyID: String, index: Int) -> String {
    "\(resourceURLPrefix)\(copyID)/\(index)"
  }

  /// The HTML flavor of a copy: the blocks and their resources as attributes of empty spans, so they add no text to a
  /// paste into another app, then `textHTML`, the formatted text of the copied text blocks. `resources` keeps the order
  /// of its placeholders.
  static func html(
    id: String,
    blocks: String,
    resources: [(url: String, resource: Resource)],
    textHTML: String,
  ) -> String {
    var html = "<span data-cesdk-blocks-version=\"\(version)\" data-cesdk-blocks-id=\"\(escape(id))\" "
      + "data-cesdk-blocks=\"\(escape(blocks))\"></span>"
    for (url, resource) in resources {
      let dataURL = "data:\(resource.mimeType);base64,\(resource.data.base64EncodedString())"
      html += "<span data-cesdk-resource=\"\(escape(url))\" data-cesdk-resource-data=\"\(escape(dataURL))\"></span>"
    }
    return html + textHTML
  }

  /// Finds a CE.SDK copy in the HTML flavor of the clipboard. Browsers and other apps wrap the HTML in a document and
  /// may write the attributes in either quote style, so the scan reads each tag and does not expect the span at the
  /// root.
  static func parse(html: String) -> Payload? {
    // A cheap test first: most pastes carry no CE.SDK blocks.
    guard html.contains("data-cesdk-blocks") else { return nil }
    var id: String?
    var blocks = ""
    var resources: [String: Resource] = [:]
    for attributes in tags(in: Array(html.utf8)) {
      if let blocksAttribute = attributes["data-cesdk-blocks"], id == nil {
        guard attributes["data-cesdk-blocks-version"] == version else { return nil }
        id = attributes["data-cesdk-blocks-id"] ?? ""
        blocks = blocksAttribute
      } else if let url = attributes["data-cesdk-resource"],
                // Only the URLs of this format: a forged copy cannot move a URL of the scene.
                url.hasPrefix(resourceURLPrefix),
                let dataURL = attributes["data-cesdk-resource-data"],
                let resource = decodeDataURL(dataURL) {
        resources[url] = resource
      }
    }
    guard let id else { return nil }
    return Payload(id: id, blocks: blocks, resources: resources)
  }

  /// Decodes a `data:` URI to its bytes and MIME type. `nil` when it is no `data:` URI or its base64 is invalid.
  static func decodeDataURL(_ url: String) -> Resource? {
    guard url.hasPrefix("data:"), let comma = url.firstIndex(of: ",") else { return nil }
    let header = url[url.index(url.startIndex, offsetBy: 5) ..< comma]
    let payload = url[url.index(after: comma)...]
    let mimeType = header.split(separator: ";", omittingEmptySubsequences: false).first.map(String.init) ?? ""
    if header.hasSuffix(";base64") {
      guard let data = Data(base64Encoded: String(payload), options: .ignoreUnknownCharacters) else { return nil }
      return Resource(mimeType: mimeType, data: data)
    }
    return Resource(mimeType: mimeType, data: percentDecoded(payload))
  }

  // MARK: - HTML

  private static func escape(_ value: String) -> String {
    var escaped = ""
    escaped.reserveCapacity(value.utf8.count)
    for character in value.unicodeScalars {
      switch character {
      case "&": escaped += "&amp;"
      case "\"": escaped += "&quot;"
      case "<": escaped += "&lt;"
      case ">": escaped += "&gt;"
      default: escaped.unicodeScalars.append(character)
      }
    }
    return escaped
  }

  /// The attributes of each start tag in `html`, with their character references decoded. Works on the UTF-8 bytes,
  /// because the HTML of a copy with images holds megabytes.
  private static func tags(in html: [UInt8]) -> [[String: String]] {
    var scanner = TagScanner(html: html)
    var result: [[String: String]] = []
    while let attributes = scanner.nextTag() {
      if !attributes.isEmpty {
        result.append(attributes)
      }
    }
    return result
  }

  private struct TagScanner {
    let html: [UInt8]
    var index = 0

    init(html: [UInt8]) {
      self.html = html
    }

    /// The attributes of the next start tag, or `nil` at the end of the HTML.
    mutating func nextTag() -> [String: String]? {
      while let open = html[index...].firstIndex(of: UInt8(ascii: "<")) {
        index = open + 1
        guard index < html.count, isLetter(html[index]) else { continue }
        skip { !isSpace($0) && $0 != UInt8(ascii: ">") }
        var attributes: [String: String] = [:]
        while let (name, value) = nextAttribute() {
          attributes[name] = value
        }
        return attributes
      }
      return nil
    }

    private mutating func nextAttribute() -> (String, String)? {
      skip { isSpace($0) || $0 == UInt8(ascii: "/") }
      guard index < html.count, html[index] != UInt8(ascii: ">") else { return nil }
      let nameStart = index
      skip { !isSpace($0) && $0 != UInt8(ascii: "=") && $0 != UInt8(ascii: ">") }
      let name = String(bytes: html[nameStart ..< index], encoding: .utf8)?.lowercased() ?? ""
      skip(while: isSpace)
      guard index < html.count, html[index] == UInt8(ascii: "=") else { return (name, "") }
      index += 1
      skip(while: isSpace)
      guard index < html.count else { return (name, "") }
      let quote = html[index]
      if quote == UInt8(ascii: "\"") || quote == UInt8(ascii: "'") {
        let valueStart = index + 1
        let valueEnd = html[valueStart...].firstIndex(of: quote) ?? html.count
        index = min(valueEnd + 1, html.count)
        return (name, unescape(html[valueStart ..< valueEnd]))
      }
      let valueStart = index
      skip { !isSpace($0) && $0 != UInt8(ascii: ">") }
      return (name, unescape(html[valueStart ..< index]))
    }

    private mutating func skip(while condition: (UInt8) -> Bool) {
      while index < html.count, condition(html[index]) {
        index += 1
      }
    }
  }

  private static let namedReferences: [String: String] = [
    "amp": "&", "quot": "\"", "lt": "<", "gt": ">", "apos": "'", "nbsp": "\u{00A0}",
  ]

  /// Decodes the named references that browsers write in attributes and every numeric reference.
  private static func unescape(_ bytes: ArraySlice<UInt8>) -> String {
    let text = String(bytes: bytes, encoding: .utf8) ?? ""
    guard text.contains("&") else { return text }
    var result = ""
    var rest = text[...]
    while let ampersand = rest.firstIndex(of: "&") {
      result += rest[..<ampersand]
      let afterAmpersand = rest.index(after: ampersand)
      guard let semicolon = rest[afterAmpersand...].prefix(10).firstIndex(of: ";") else {
        result += "&"
        rest = rest[afterAmpersand...]
        continue
      }
      let reference = String(rest[afterAmpersand ..< semicolon])
      if let decoded = decodeReference(reference) {
        result += decoded
        rest = rest[rest.index(after: semicolon)...]
      } else {
        result += "&"
        rest = rest[afterAmpersand...]
      }
    }
    return result + rest
  }

  private static func decodeReference(_ reference: String) -> String? {
    if let named = namedReferences[reference] {
      return named
    }
    guard reference.hasPrefix("#") else { return nil }
    let digits = reference.dropFirst()
    let value = digits.first == "x" || digits.first == "X"
      ? UInt32(digits.dropFirst(), radix: 16)
      : UInt32(digits, radix: 10)
    return value.flatMap(Unicode.Scalar.init).map { String(Character($0)) }
  }

  /// Percent-decodes to bytes. A `%` without two hex digits stays as it is.
  private static func percentDecoded(_ text: Substring) -> Data {
    let bytes = Array(text.utf8)
    var data = Data(capacity: bytes.count)
    var index = 0
    while index < bytes.count {
      if bytes[index] == UInt8(ascii: "%"), index + 2 < bytes.count,
         let hex = String(bytes: bytes[index + 1 ... index + 2], encoding: .utf8), hex.allSatisfy(\.isHexDigit),
         let byte = UInt8(hex, radix: 16) {
        data.append(byte)
        index += 3
      } else {
        data.append(bytes[index])
        index += 1
      }
    }
    return data
  }

  private static func isSpace(_ byte: UInt8) -> Bool {
    byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0C || byte == 0x0D
  }

  private static func isLetter(_ byte: UInt8) -> Bool {
    (UInt8(ascii: "a") ... UInt8(ascii: "z")).contains(byte) || (UInt8(ascii: "A") ... UInt8(ascii: "Z")).contains(byte)
  }
}
