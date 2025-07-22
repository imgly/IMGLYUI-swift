import SwiftUI

struct VolumeOptionsSheet: View {
  var body: some View {
    DismissableTitledSheet(.imgly.localized("ly_img_editor_sheet_volume_title")) {
      VolumeOptions()
    }
  }
}
