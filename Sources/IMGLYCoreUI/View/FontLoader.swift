import SwiftUI

@_spi(Internal) public struct FontLoader<Content: View, Placeholder: View>: View {
  let fontURL: URL?
  @ViewBuilder let content: (_ fontName: String) -> Content
  @ViewBuilder let placeholder: () -> Placeholder

  @State private var fontName: String?

  @_spi(Internal) public init(
    fontURL: URL?,
    @ViewBuilder content: @escaping (_ fontName: String) -> Content,
    @ViewBuilder placeholder: @escaping () -> Placeholder
  ) {
    self.fontURL = fontURL
    self.content = content
    self.placeholder = placeholder
  }

  @_spi(Internal) public var body: some View {
    Group {
      if let fontName {
        content(fontName)
      } else {
        placeholder()
      }
    }
    .task(id: fontURL) {
      do {
        guard let fontURL else {
          fontName = "" // Fallback system font
          return
        }
        if let registeredFontName = FontImporter.registeredFonts[fontURL] {
          fontName = registeredFontName
          return
        }
        // Show placeholder only for uncached fonts before network request when font URL changes
        fontName = nil
        let (data, _) = try await URLSession.shared.data(from: fontURL)
        let fonts = FontImporter.importFonts([fontURL: data])
        if let name = fonts.first?.value {
          fontName = name
          return
        }
      } catch {}
      fontName = "" // Fallback system font
    }
  }
}
