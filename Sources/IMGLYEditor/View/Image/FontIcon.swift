import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct FontIcon: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id
  private var fontLibrary: FontLibrary { interactor.fontLibrary }

  var body: some View {
    let text = interactor.bindTextState(id, resetFontProperties: true)

    if let assetID = text.wrappedValue.assetID,
       let typeface = fontLibrary.typefaceFor(id: assetID),
       let fontName = typeface.previewFontName {
      FontImage(font: .custom(fontName, size: 28))
    }
  }
}
