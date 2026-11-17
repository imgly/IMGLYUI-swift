import Foundation

enum ClipboardSVG {
  /// Whether `text` is SVG markup: its root element is `<svg>`, after an optional byte order mark, XML declaration,
  /// comments and doctype. Adobe Illustrator copies its selection as such markup in plain text. A scan instead of one
  /// regular expression, because a pattern over repeated comments backtracks for a long time on text that is no SVG.
  static func isMarkup(_ text: String) -> Bool {
    var rest = Substring(text)
    if rest.first == "\u{FEFF}" {
      rest = rest.dropFirst()
    }
    while true {
      rest = rest.drop(while: \.isWhitespace)
      guard let next = afterPrologPart(rest) else { return false }
      if next.startIndex == rest.startIndex {
        break
      }
      rest = next
    }
    let start = rest.prefix(5).lowercased()
    guard start.hasPrefix("<svg"), start.count == 5, start.last!.isWhitespace || start.last == ">" else { return false }
    let end = rest.reversed().drop(while: \.isWhitespace)
    guard end.first == ">" else { return false }
    let closing = String(end.dropFirst().drop(while: \.isWhitespace).prefix(5).reversed()).lowercased()
    return closing == "</svg"
  }

  /// The text after the prolog part at the start of `text`: a declaration, a comment or a doctype with its internal
  /// subset. `text` itself when no prolog part starts there, and `nil` when the part has no end.
  private static func afterPrologPart(_ text: Substring) -> Substring? {
    for (start, end) in [("<?", "?>"), ("<!--", "-->")] where text.hasPrefix(start) {
      guard let close = text.dropFirst(start.count).range(of: end) else { return nil }
      return text[close.upperBound...]
    }
    guard text.prefix(9).uppercased() == "<!DOCTYPE" else { return text }
    guard let close = text.firstIndex(of: ">") else { return nil }
    guard let subset = text.firstIndex(of: "["), subset < close else { return text[text.index(after: close)...] }
    guard let subsetEnd = text[subset...].firstIndex(of: "]"),
          let subsetClose = text[subsetEnd...].firstIndex(of: ">") else { return nil }
    return text[text.index(after: subsetClose)...]
  }
}
