import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct ResizeOptionsSheet: View {
  @EnvironmentObject var interactor: Interactor

  var body: some View {
    DismissableTitledSheet(.imgly.localized("ly_img_editor_sheet_resize_title")) {
      TransformOptions(interactor: interactor, item: { asset in
        TransformItem(asset: asset)
      }, sources: [.init(defaultSource: .pagePresets)])
    }
  }
}
