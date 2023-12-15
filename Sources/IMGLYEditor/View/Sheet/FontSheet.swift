import SwiftUI

struct FontSheet: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id
  @Environment(\.imglyFontFamilies) private var fontFamilies
  private var fontLibrary: FontLibrary { interactor.fontLibrary }

  var fonts: [FontFamily] {
    if let fontFamilies {
      return fontFamilies.compactMap {
        fontLibrary.fontFamilyFor(id: $0)
      }
    } else {
      return fontLibrary.fonts
    }
  }

  var body: some View {
    let text = interactor.bindTextState(id, resetFontProperties: true)

    BottomSheet {
      ListPicker(data: fonts, selection: text.fontFamilyID) { fontFamily, isSelected in
        Label(fontFamily.name, systemImage: "checkmark")
          .labelStyle(.icon(hidden: !isSelected, titleFont: .custom(fontFamily.someFontName ?? "", size: 17)))
      }
    }
  }
}

struct FontSheet_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews(sheet: .init(.font(nil, nil), .font))
  }
}
