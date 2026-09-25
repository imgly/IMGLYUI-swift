@_spi(Internal) import IMGLYCoreUI
import SwiftUI

/// Groups the playback controls as a bar to be used above the timeline.
struct PlayerBarView: View {
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  @EnvironmentObject var interactor: AnyTimelineInteractor
  @EnvironmentObject var player: Player

  @Binding var isTimelineMinimized: Bool

  var body: some View {
    CenteredLeadingTrailing {
      PlayButton()
        .font(.system(size: 24))
        .frame(width: 40, height: 40)
        .keyboardShortcut(.space, modifiers: [])
    } leading: {
      TimecodeView()
        .padding(.leading)
      Spacer()
    } trailing: {
      ToggleButton(
        isEnabled: interactor.isLoopingPlaybackEnabled,
        icon: Image("custom.video.repeat", bundle: .module),
        disabledIcon: Image("custom.video.repeat.slash", bundle: .module),
        changeCallback: {
          interactor.toggleIsLoopingPlaybackEnabled()
        },
      )
      .accessibilityLabel(Text(.imgly.localized("ly_img_editor_timeline_button_loop")))
      .font(.system(size: 18))
      .padding(.horizontal, 8)

      Spacer()

      if verticalSizeClass != .compact {
        Button {
          toggleTimeline()
        } label: {
          ZStack(alignment: .trailing) {
            Label {
              Text(.imgly.localized("ly_img_editor_timeline_button_show_timeline"))
                .font(.footnote)
                .fontWeight(.semibold)
            } icon: {
              Image("custom.timeline", bundle: .module)
            }
            .opacity(isTimelineMinimized ? 1 : 0)

            Label {} icon: {
              Image(systemName: "chevron.down")
                .fontWeight(.semibold)
            }
            .opacity(!isTimelineMinimized ? 1 : 0)
          }
          .frame(minWidth: 44, minHeight: 40)
          .contentShape(Rectangle())
          .padding(.trailing)
        }
        .buttonStyle(.plain)
        .transition(.opacity)
        .accessibilityLabel(Text(isTimelineMinimized ? .imgly
            .localized("ly_img_editor_timeline_button_show_timeline") : .imgly
            .localized("ly_img_editor_timeline_button_hide_timeline")))
      }
    }
  }

  private func toggleTimeline() {
    withAnimation(.imgly.timelineMinimizeMaximize) {
      isTimelineMinimized.toggle()
    }
  }
}
