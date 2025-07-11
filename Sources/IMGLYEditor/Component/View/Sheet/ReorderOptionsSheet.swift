import SwiftUI

struct ReorderOptionsSheet: View {
  var body: some View {
    DismissableTitledSheet(.imgly.localized("ly_img_editor_sheet_reorder_title")) {
      ReorderOptions()
    }
  }
}
