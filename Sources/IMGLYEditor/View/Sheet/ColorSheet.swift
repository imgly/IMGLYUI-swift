@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct ColorSheet: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  var fillColor: Binding<CGColor> {
    interactor.bind(id, property: .key(.fillSolidColor), default: .imgly.black,
                    setter: Interactor.Setter.set(overrideScopes: [.key(.fillChange), .key(.strokeChange)]),
                    completion: nil)
  }

  var body: some View {
    DismissableTitledSheet(.imgly.localized("ly_img_editor_postcard_sheet_colors_title")) {
      List {
        if interactor.supportsFill(id) {
          ColorOptions(title: "Color", color: fillColor, addUndoStep: interactor.addUndoStep)
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
        }
      }
    }
  }
}
