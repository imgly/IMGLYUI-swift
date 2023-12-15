import SwiftUI

struct FontIcon: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id
  private var fontLibrary: FontLibrary { interactor.fontLibrary }

  var body: some View {
    let text = interactor.bindTextState(id, resetFontProperties: true)

    if let fontFamilyID = text.wrappedValue.fontFamilyID,
       let fontFamily = fontLibrary.fontFamilyFor(id: fontFamilyID),
       let fontName = fontFamily.someFontName {
      FontImage(font: .custom(fontName, size: 28))
    }
  }
}
