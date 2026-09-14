@_spi(Internal) import IMGLYCore
import SwiftUI

struct FillStrokeOptionsSheet: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  var title: LocalizedStringResource {
    let showFill = interactor.isColorFill(id) && interactor.supportsFill(id) && interactor.isAllowed(
      id,
      scope: .fillChange,
    )
    let showStroke = interactor.supportsStroke(id) && interactor.isAllowed(id, scope: .strokeChange)
    if showFill, showStroke {
      return .imgly.localized("ly_img_editor_sheet_fill_stroke_title_fill_stroke")
    } else if showFill {
      return .imgly.localized("ly_img_editor_sheet_fill_stroke_title_fill")
    } else {
      return .imgly.localized("ly_img_editor_sheet_fill_stroke_title_stroke")
    }
  }

  var body: some View {
    DismissableTitledSheet(title) {
      FillAndStrokeOptions()
    }
  }
}
