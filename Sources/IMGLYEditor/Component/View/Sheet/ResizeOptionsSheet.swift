import SwiftUI
@_spi(Internal) import IMGLYCoreUI

struct ResizeOptionsSheet: View {
  @EnvironmentObject var interactor: Interactor

  var body: some View {
    DismissableTitledSheet("Resize") {
      TransformOptions(interactor: interactor, item: { asset in
        TransformItem(asset: asset)
      }, sources: [.init(id: "ly.img.page.presets")])
    }
  }
}
