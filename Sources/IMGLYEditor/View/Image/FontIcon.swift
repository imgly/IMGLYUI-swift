import SwiftUI
@_spi(Internal) import IMGLYCoreUI

@_spi(Internal) public struct FontIcon: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id
  private var fontLibrary: FontLibrary { interactor.fontLibrary }

  @_spi(Internal) public init() {}

  @_spi(Internal) public var body: some View {
    let text = interactor.bindTextState(id, resetFontProperties: true)

    if let assetID = text.wrappedValue.assetID,
       let typeface = fontLibrary.typefaceFor(id: assetID) {
      FontLoader(fontURL: typeface.previewFont?.uri) { fontName in
        FontImage(font: .custom(fontName, size: 28))
      } placeholder: {
        FontImage(font: .custom("", size: 28))
      }
    }
  }
}
