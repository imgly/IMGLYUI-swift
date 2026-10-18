import SwiftUI

/// The play button.
struct PlayButton: View {
  @EnvironmentObject var interactor: AnyTimelineInteractor
  @EnvironmentObject var player: Player

  var body: some View {
    Button {
      interactor.togglePlayback()
      HapticsHelper.shared.playPause()
    } label: {
      ZStack {
        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(Text(player.isPlaying ? .imgly.localized("ly_img_editor_timeline_button_pause") : .imgly
        .localized("ly_img_editor_timeline_button_play")))
  }
}
