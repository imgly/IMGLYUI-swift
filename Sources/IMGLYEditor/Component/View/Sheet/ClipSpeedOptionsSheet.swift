import SwiftUI
@_spi(Internal) import IMGLYCore

struct ClipSpeedOptionsSheet: View {
  @EnvironmentObject private var interactor: Interactor
  @Environment(\.imglyTimelineConfiguration) private var timelineConfiguration

  var body: some View {
    DismissableTitledSheet(.imgly.localized("ly_img_editor_sheet_clip_speed_title")) {
      ClipSpeedOptions(interactor: interactor, timelineConfiguration: timelineConfiguration)
    }
  }
}
