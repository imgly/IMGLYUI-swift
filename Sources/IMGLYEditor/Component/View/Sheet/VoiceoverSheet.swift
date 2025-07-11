import SwiftUI

struct VoiceoverSheet: View {
  var body: some View {
    TitledSheet(.imgly.localized("ly_img_editor_sheet_voiceover_title")) {
      VoiceOverSheet()
    }
  }
}
