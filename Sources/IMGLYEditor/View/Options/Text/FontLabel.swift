@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI

import SwiftUI

struct FontLabel: View {
  let fontURL: URL
  let isSelected: Bool
  let title: LocalizedStringKey

  var body: some View {
    FontLoader(fontURL: fontURL) { fontName in
      Label(title, systemImage: "checkmark")
        .labelStyle(.icon(hidden: !isSelected,
                          titleFont: .custom(fontName, size: 17)))
    } placeholder: {
      Label(title, systemImage: "checkmark")
        .labelStyle(.icon(hidden: !isSelected))
      Spacer()
    }
  }
}
