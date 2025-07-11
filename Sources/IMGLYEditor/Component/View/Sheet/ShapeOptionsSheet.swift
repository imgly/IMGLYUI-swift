import SwiftUI

struct ShapeOptionsSheet: View {
  var body: some View {
    DismissableTitledSheet(.imgly.localized("ly_img_editor_sheet_shape_title")) {
      ShapeOptions()
    }
  }
}
