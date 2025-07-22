import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct CropOptionsSheet: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglySelection) private var id

  var body: some View {
    CustomizableTitledSheet(.imgly.localized("ly_img_editor_sheet_crop_title")) {
      CropOptions()
    } leading: {
      // Do not use ActionButton here as placing it inside toolbar
      // will hide the title of the label.
      let action = Action.resetCrop
      Button {
        interactor.actionButtonTapped(for: action)
      } label: {
        HStack {
          if let imageName = action.imageName {
            if action.isSystemImage {
              Image(systemName: imageName)
            } else {
              Image(imageName, bundle: .module)
            }
          }
          Text(action.localizedStringResource)
        }
      }
      .disabled(!interactor.canResetCrop(id))
      .tint(.primary)
    }
    .ignoresSafeArea(.keyboard)
  }
}
