import IMGLYEngine

@_spi(Internal) public struct FontProperties: Equatable {
  @_spi(Internal) public let bold: Bool?
  @_spi(Internal) public let italic: Bool?

  @_spi(Internal) public init(bold: Bool?, italic: Bool?) {
    self.bold = bold
    self.italic = italic
  }
}

private extension Font {
  var isRegular: Bool { weight == .normal }
  var isBold: Bool { weight == .bold }
  var isItalic: Bool { style == .italic }
}

@_spi(Internal) public extension Typeface {
  private var regularFont: IMGLYEngine.Font? { font(for: .init(bold: false, italic: false)) }
  private var boldItalicFont: IMGLYEngine.Font? { font(for: .init(bold: true, italic: true)) }
  private var boldFont: IMGLYEngine.Font? { font(for: .init(bold: true, italic: false)) }
  private var italicFont: IMGLYEngine.Font? { font(for: .init(bold: false, italic: true)) }

  var previewFont: IMGLYEngine.Font? {
    regularFont ?? boldFont ?? italicFont ?? boldItalicFont ?? fonts.first
  }

  @MainActor
  var previewFontName: String? {
    guard let previewFont else {
      return nil
    }
    return FontImporter.registeredFonts[previewFont.uri]
  }

  func font(for properties: FontProperties) -> IMGLYEngine.Font? {
    fonts.first { font in
      switch properties {
      case .init(bold: false, italic: false): font.isRegular && !font.isItalic
      case .init(bold: true, italic: false): font.isBold && !font.isItalic
      case .init(bold: true, italic: true): font.isBold && font.isItalic
      case .init(bold: false, italic: true): font.isRegular && font.isItalic
      default:
        false
      }
    }
  }
}
