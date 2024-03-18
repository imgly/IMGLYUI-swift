import SwiftUI

/// Shows the current playhead position and the total duration as text.
struct TimecodeView: View {
  @EnvironmentObject var timeline: Timeline
  @EnvironmentObject var player: Player

  var body: some View {
    HStack {
      Text(player.formattedPlayheadPosition)
      Text("/")
        .foregroundColor(.secondary)
      Text(timeline.formattedTotalDuration)
        .foregroundColor(.secondary)
    }
    .font(.footnote)
    .fontWeight(.semibold)
    .monospacedDigit()
  }
}
