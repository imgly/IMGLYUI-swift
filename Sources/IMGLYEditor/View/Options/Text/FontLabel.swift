@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI

import SwiftUI

struct FontLabel: View {
  let fontURL: URL
  let isSelected: Bool
  let title: LocalizedStringResource

  var body: some View {
    FontLoader(fontURL: fontURL) { fontName in
      Label {
        Text(title)
      } icon: {
        Image(systemName: "checkmark")
      }
      .labelStyle(.icon(hidden: !isSelected,
                        titleFont: .custom(fontName, size: 17)))
    } placeholder: {
      Label {
        Text(title)
      } icon: {
        Image(systemName: "checkmark")
      }
      .labelStyle(.icon(hidden: !isSelected))
      Spacer()
    }
  }
}
