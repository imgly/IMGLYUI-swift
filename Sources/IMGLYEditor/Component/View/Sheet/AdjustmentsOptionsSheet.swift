import SwiftUI

struct AdjustmentsOptionsSheet: View {
  var body: some View {
    DismissableTitledSheet(.imgly.localized("ly_img_editor_sheet_adjustments_title")) {
      AdjustmentsOptions()
    }
  }
}
