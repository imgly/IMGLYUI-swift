import CoreGraphics
@_spi(Internal) import IMGLYCoreUI

struct TextState: BatchMutable {
  var assetID: String?

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
}
