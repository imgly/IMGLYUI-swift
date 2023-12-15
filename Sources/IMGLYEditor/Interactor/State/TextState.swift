import CoreGraphics

struct TextState: BatchMutable {
  var fontID: String?
  var fontFamilyID: String?

  var bold: TextProperty?
  var italic: TextProperty?

  var isBold: Bool { bold == .bold }
  var isItalic: Bool { italic == .italic }

  mutating func setFontProperties(_ properties: FontProperties?) {
    guard let properties else {
      bold = nil
      italic = nil
      return
    }
    if let bold = properties.bold {
      self.bold = bold ? .bold : .inactive
    } else {
      bold = nil
    }
    if let italic = properties.italic {
      self.italic = italic ? .italic : .inactive
    } else {
      italic = nil
    }
  }

  func fontFamilyName(_ fontLibrary: FontLibrary) -> String? {
    guard let fontFamilyID else {
      return nil
    }
    return fontLibrary.fontFamilyFor(id: fontFamilyID)?.name
  }
}
