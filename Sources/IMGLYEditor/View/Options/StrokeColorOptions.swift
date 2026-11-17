@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct StrokeColorOptions: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  var body: some View {
    if interactor.supportsStroke(id) {
      ColorOptions(title: .imgly.localized("ly_img_editor_sheet_fill_stroke_color_picker_title_stroke"),
                   isEnabled: interactor.bind(id, property: .key(.strokeEnabled), default: false),
                   color: interactor.bind(id, property: .key(.strokeColor), default: .imgly.black, completion:
                     Interactor.Completion.set(property: .key(.strokeEnabled), value: true)),
                   addUndoStep: interactor.addUndoStep,
                   style: .stroke)
    }
  }
}
