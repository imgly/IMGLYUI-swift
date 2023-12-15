import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct SelectionColorsIcon: View {
  @EnvironmentObject private var interactor: Interactor

  var body: some View {
    HStack(spacing: -16) {
      let sections = interactor.bind(interactor.selectionColors, completion: nil)
      ForEach(sections, id: \.name) { section in
        ForEach(section.colors) { color in
          FillColorImage(isEnabled: true, color: color.binding)
        }
      }
    }
  }
}
