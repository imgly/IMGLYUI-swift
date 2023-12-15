import SwiftUI

class FontLibrary {
  var fonts: [FontFamily] = []

  func fontFamilyFor(id fontFamilyID: String) -> FontFamily? {
    fonts.first { family in
      family.id == fontFamilyID
    }
  }

  func fontFor(id fontID: String) -> FontPair? {
    for family in fonts {
      if let font = family.fontFor(id: fontID) {
        return .init(family: family, font: font)
      }
    }
    return nil
  }

  func fontFor(url fontURL: URL) -> FontPair? {
    for family in fonts {
      if let font = family.fontFor(url: fontURL) {
        return .init(family: family, font: font)
      }
    }
    return nil
  }
}
