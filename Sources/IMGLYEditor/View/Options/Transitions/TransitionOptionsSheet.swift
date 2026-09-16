import SwiftUI

struct TransitionOptionsSheet: View {
  var body: some View {
    DismissableTitledSheet(.imgly.localized("ly_img_editor_sheet_transition_title")) {
      TransitionOptions()
    }
  }
}
