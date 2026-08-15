import SwiftUI

struct CaptionStyleOptionsSheet: View {
  var body: some View {
    DismissableTitledSheet(.imgly.localized("ly_img_editor_sheet_caption_style_title")) {
      CaptionStyleOptions()
    }
  }
}
