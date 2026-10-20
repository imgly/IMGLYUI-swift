@_spi(Internal) import IMGLYCoreUI
import SwiftUI

extension EnvironmentValues {
  /// A binding to the timeline's expanded state, injected by ``Timeline`` around
  /// the whole timeline, so an item can toggle it from the header or the body.
  @Entry var imglyTimelineIsExpanded: Binding<Bool>?
}

/// The built-in timecode display of the timeline header.
struct TimelineTimecodeItem: View {
  /// Replaces the built-in timecode display when set.
  var label: (() -> AnyView)?

  var body: some View {
    Group {
      if let label {
        label()
      } else {
        TimecodeView()
      }
    }
    .padding(.leading)
  }
}

/// The built-in play/pause button of the timeline header.
struct TimelinePlayPauseItem: View {
  /// Replaces the built-in play/pause behavior when set.
  var action: (() -> Void)?
  /// Replaces the built-in play/pause glyph when set.
  var icon: (() -> AnyView)?

  var body: some View {
    PlayButton(action: action, icon: icon)
      .font(.system(size: 24))
      .frame(width: 40, height: 40)
      .keyboardShortcut(.space, modifiers: [])
  }
}

/// The built-in looping toggle of the timeline header.
struct TimelineLoopItem: View {
  /// Replaces the built-in looping toggle when set.
  var action: (() -> Void)?
  /// Replaces the built-in looping icons when set.
  var icon: (() -> AnyView)?

  @EnvironmentObject private var interactor: AnyTimelineInteractor

  private func toggle() {
    if let action {
      action()
    } else {
      interactor.toggleIsLoopingPlaybackEnabled()
    }
  }

  var body: some View {
    Group {
      if let icon {
        // ToggleButton takes a state-dependent icon pair, so a single replacement icon gets a plain button.
        Button { toggle() } label: { icon() }
          .buttonStyle(.plain)
      } else {
        ToggleButton(
          isEnabled: interactor.isLoopingPlaybackEnabled,
          icon: Image("custom.video.repeat", bundle: .module),
          disabledIcon: Image("custom.video.repeat.slash", bundle: .module),
          changeCallback: { toggle() },
        )
      }
    }
    .accessibilityLabel(Text(.imgly.localized("ly_img_editor_timeline_button_loop")))
    .font(.system(size: 18))
    .padding(.horizontal, 8)
  }
}

/// The built-in expand/collapse toggle of the timeline header.
///
/// Reads the expanded binding that ``Timeline`` injects around the whole timeline,
/// so it also works when placed outside the header.
struct TimelineToggleExpandedItem: View {
  /// Replaces the built-in expand/collapse behavior when set.
  var action: (() -> Void)?
  /// Replaces the built-in expand/collapse label when set.
  var label: (() -> AnyView)?

  @Environment(\.imglyTimelineIsExpanded) private var isExpanded

  var body: some View {
    if let isExpanded {
      let isCollapsed = !isExpanded.wrappedValue
      Button {
        if let action {
          action()
        } else {
          isExpanded.wrappedValue.toggle()
        }
      } label: {
        Group {
          if let label {
            label()
          } else {
            builtInLabel(isCollapsed: isCollapsed)
          }
        }
        .frame(minWidth: 44, minHeight: 40)
        .contentShape(Rectangle())
        .padding(.trailing)
      }
      .buttonStyle(.plain)
      .transition(.opacity)
      .accessibilityLabel(Text(isCollapsed ? .imgly
          .localized("ly_img_editor_timeline_button_show_timeline") : .imgly
          .localized("ly_img_editor_timeline_button_hide_timeline")))
    }
  }

  private func builtInLabel(isCollapsed: Bool) -> some View {
    ZStack(alignment: .trailing) {
      Label {
        Text(.imgly.localized("ly_img_editor_timeline_button_show_timeline"))
          .font(.footnote)
          .fontWeight(.semibold)
      } icon: {
        Image("custom.timeline", bundle: .module)
      }
      .opacity(isCollapsed ? 1 : 0)

      Label {} icon: {
        Image(systemName: "chevron.down")
          .fontWeight(.semibold)
      }
      .opacity(isCollapsed ? 0 : 1)
    }
  }
}
