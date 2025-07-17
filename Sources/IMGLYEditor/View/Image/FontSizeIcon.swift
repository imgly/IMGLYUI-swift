@_spi(Internal) import IMGLYCore
import SwiftUI

struct FontSizeIcon: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  var body: some View {
    let fontSize: Binding<Float?> = interactor.bind(id, property: .key(.textFontSize))

    if let fontSize = fontSize.wrappedValue {
      FontSizeImage(fontSize: fontSize)
    }
  }
}
