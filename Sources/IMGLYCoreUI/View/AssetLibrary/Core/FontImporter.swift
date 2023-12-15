import UIKit

@MainActor
@_spi(Internal) public enum FontImporter {
  @_spi(Internal) public static var registeredFonts = [String: String]()
  private static var registeredFontNames = [String]()

  @_spi(Internal) public static func importFonts(_ fonts: [String: Data]) -> [String: String] {
    // There is a bug in Apple's font loading system, dating back to at least 2010
    // (https://lists.apple.com/archives/cocoa-dev/2010/Sep/msg00450.html and
    // http://www.openradar.me/18778790) which can lead to a deadlock when loading custom fonts.
    // This seems to happen very rarely and has only been reproduced with iOS 10 so far, but adding
    // the below line works around the issue, so we're adding it to be on the safe side.
    _ = UIFont()

    var fontIDtoName = [String: String]()

    for font in fonts {
      guard
        let provider = CGDataProvider(data: font.value as CFData),
        let cgfont = CGFont(provider) else {
        continue
      }

      var error: Unmanaged<CFError>?

      guard let fontName = cgfont.postScriptName as String? else {
        continue
      }

      fontIDtoName[font.key] = fontName

      if registeredFontNames.contains(fontName) {
        // Font has already been registered
        continue
      }

      let registered = CTFontManagerRegisterGraphicsFont(cgfont, &error)

      if !registered {
        if let error = error?.takeUnretainedValue() as Swift.Error? {
          print("Failed to register font, error: \(error.localizedDescription)")
        }
      } else {
        registeredFontNames.append(fontName)
      }
    }

    registeredFonts.merge(fontIDtoName) { _, new in
      new
    }
    return fontIDtoName
  }
}
