import SwiftUI

/// The play button.
struct PlayButton: View {
  /// Replaces the built-in play/pause behavior when set.
  var action: (() -> Void)?
  /// Replaces the built-in play/pause glyph when set.
  var icon: (() -> AnyView)?

  @EnvironmentObject var interactor: AnyTimelineInteractor
  @EnvironmentObject var player: Player

  var body: some View {
    Button {
      if let action {
        action()
      } else {
        interactor.togglePlayback()
        HapticsHelper.shared.playPause()
      }
    } label: {
      ZStack {
        if let icon {
          icon()
        } else {
          Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(Text(player.isPlaying ? .imgly.localized("ly_img_editor_timeline_button_pause") : .imgly
        .localized("ly_img_editor_timeline_button_play")))
  }
}
