import IMGLYEngine

@MainActor
extension BlockAPI {
  /// The text selection when characters are highlighted, otherwise the whole
  /// text.
  func effectiveTextRange(_ id: DesignBlockID) throws -> Range<String.Index> {
    if let cursor = try getTextCursorRange(), cursor.lowerBound != cursor.upperBound {
      return cursor
    }
    let text = try getString(id, property: "text/text")
    return text.startIndex ..< text.endIndex
  }

  /// The list style shared across the paragraphs at the text cursor/selection, or `nil` when they
  /// use mixed styles. Empty text resolves to `.none`.
  func resolveTextListStyle(_ id: DesignBlockID) throws -> ListStyle? {
    let cursorRange = try getTextCursorRange()
    let indices = try getTextParagraphIndices(id, in: cursorRange)
    guard !indices.isEmpty else { return .none }
    let styles = try indices.map { try getTextListStyle(id, paragraphIndex: $0) }
    guard let first = styles.first else { return .none }
    return styles.dropFirst().allSatisfy { $0 == first } ? first : nil
  }

  /// The id of the typeface font shared across ``effectiveTextRange(_:)`` — the
  /// font matching the uniform style and weight of the whole range — or `nil`
  /// when the range mixes multiple styles or weights.
  func resolveTextFontID(_ id: DesignBlockID) throws -> String? {
    let range = try effectiveTextRange(id)
    let styles = try getTextFontStyles(id, in: range)
    let weights = try getTextFontWeights(id, in: range)
    guard let style = styles.first, let weight = weights.first,
          styles.dropFirst().allSatisfy({ $0 == style }),
          weights.dropFirst().allSatisfy({ $0 == weight }) else {
      return nil
    }
    let typeface = try getTypeface(id)
    return typeface.fonts.first { $0.style == style && $0.weight == weight }?.id
  }
}
