@_spi(Internal) import IMGLYCore
import SwiftUI

struct BackgroundOptionsSheet: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  var body: some View {
    DismissableTitledSheet(.imgly.localized("ly_img_editor_sheet_text_background_title")) {
      BackgroundOptions(isEnabled: interactor.bind(id,
                                                   property: .key(.backgroundColorEnabled),
                                                   default: false))
    }
  }
}
