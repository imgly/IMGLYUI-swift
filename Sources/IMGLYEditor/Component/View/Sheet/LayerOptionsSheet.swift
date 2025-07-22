import SwiftUI

struct LayerOptionsSheet: View {
  var body: some View {
    DismissableTitledSheet(.imgly.localized("ly_img_editor_sheet_layer_title")) {
      LayerOptions()
    }
  }
}
