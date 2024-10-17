@_spi(Internal) import IMGLYCoreUI
import SwiftUI

/// Groups the playback controls as a bar to be used above the timeline.
struct PlayerBarView: View {
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  @EnvironmentObject var interactor: AnyTimelineInteractor
  @EnvironmentObject var player: Player

  @Binding var isTimelineMinimized: Bool
  @Binding var isTimelineAnimating: Bool

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
        }
      )
      .accessibilityLabel("Loop Playback")
      .font(.system(size: 18))
      .padding(.horizontal, 8)

      Spacer()

      if verticalSizeClass != .compact {
        Button {
          toggleTimeline()
        } label: {
          ZStack(alignment: .trailing) {
            Label {
              Text("Timeline")
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
        .accessibilityLabel(isTimelineMinimized ? "Expand Timeline" : "Collapse Timeline")
      }
    }
  }

  private func toggleTimeline() {
    if #available(iOS 17.0, *) {
      isTimelineAnimating = true
      withAnimation(.imgly.timelineMinimizeMaximize) {
        isTimelineMinimized.toggle()
      } completion: {
        isTimelineAnimating = false
      }
    } else {
      isTimelineAnimating = true
      withAnimation(.imgly.timelineMinimizeMaximize) {
        isTimelineMinimized.toggle()
      }
      // Estimate the duration of the animation
      let animationDuration: TimeInterval = 0.5
      DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
        isTimelineAnimating = false
      }
    }
  }
}
