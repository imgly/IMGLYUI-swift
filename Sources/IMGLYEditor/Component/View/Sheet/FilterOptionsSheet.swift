import SwiftUI

struct FilterOptionsSheet: View {
  var body: some View {
    DismissableTitledSheet(.imgly.localized("ly_img_editor_sheet_filter_title")) {
      FilterOptions()
    }
  }
}
