import SwiftUI

struct BlurOptionsSheet: View {
  var body: some View {
    DismissableTitledSheet(.imgly.localized("ly_img_editor_sheet_blur_title")) {
      BlurOptions()
    }
  }
}
