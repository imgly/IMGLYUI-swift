import SwiftUI

struct TextOnPathOptionsSheet: View {
  var body: some View {
    DismissableTitledSheet(.imgly.localized("ly_img_editor_sheet_text_on_path_title")) {
      TextOnPathOptions()
    }
  }
}
