import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct SheetDismissButton: View {
  @EnvironmentObject private var interactor: Interactor

  var body: some View {
    Button {
      interactor.sheetDismissButtonTapped()
    } label: {
      Label {
        Text(.imgly.localized("ly_img_editor_sheet_button_close"))
      } icon: {
        if #available(iOS 26.0, *), !usesLegacyDesign {
          // iOS 26 Liquid Glass: the toolbar supplies the circular background, so a plain chevron
          // avoids a doubled circle. System default size, primary tint.
          Image(systemName: "chevron.down")
            .foregroundColor(.primary)
        } else {
          // Legacy (pre-iOS 26): unchanged — filled-circle glyph at title2, secondary.
          Image(systemName: "chevron.down.circle.fill")
            .font(.title2)
            .foregroundColor(.secondary)
        }
      }
      .symbolRenderingMode(.hierarchical)
    }
  }
}
