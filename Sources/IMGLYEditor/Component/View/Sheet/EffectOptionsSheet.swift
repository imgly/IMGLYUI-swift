import SwiftUI

struct EffectOptionsSheet: View {
  var body: some View {
    DismissableTitledSheet(.imgly.localized("ly_img_editor_sheet_effect_title")) {
      FXEffectOptions()
    }
  }
}
