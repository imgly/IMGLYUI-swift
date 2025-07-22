import SwiftUI

struct FormatTextOptionsSheet: View {
  var body: some View {
    DismissableTitledSheet(.imgly.localized("ly_img_editor_sheet_format_text_title")) {
      TextFormatOptions()
    }
  }
}
