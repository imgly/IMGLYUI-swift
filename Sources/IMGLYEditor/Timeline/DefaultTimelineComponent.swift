import SwiftUI
@_spi(Internal) import IMGLYCore
import IMGLYEngine

/// The default timeline component for video editing.
@_spi(Internal) public struct DefaultTimelineComponent: View {
  /// The bottom panel context.
  private let context: BottomPanel.Context

  @State private var isMinimized = false
  @EnvironmentObject private var interactor: Interactor

  /// Creates a timeline component.
  /// - Parameter context: The bottom panel context.
  @_spi(Internal) public init(context: BottomPanel.Context) {
    self.context = context
  }

  @Environment(\.imglyTimelineConfiguration) private var configuration
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  @Environment(\.colorScheme) private var colorScheme

  private let playerBarHeight: CGFloat = 56

  // Calculate dynamic height based on content
  private var timelineHeight: CGFloat {
    if !shouldShowTimeline {
      return 0
    }

    if isMinimized {
      return playerBarHeight
    }

    // Calculate based on tracks (matching current iOS behavior)
    let trackHeight = configuration.trackHeight
    let backgroundTrackHeight = configuration.backgroundTrackHeight
    let trackSpacing = configuration.trackSpacing
    let tracksCount = CGFloat(interactor.timelineProperties.dataSource.tracks.count)
    let rulerHeight = configuration.timelineRulerHeight

    let tracksHeight = max(1, tracksCount + 1) * (trackHeight + trackSpacing) + backgroundTrackHeight
    let totalHeight = playerBarHeight + tracksHeight + rulerHeight + trackSpacing * 3

    // Limit to max height of 260 (matching current iOS)
    return min(260, totalHeight)
  }

  private var shouldShowTimeline: Bool {
    if let sceneMode = try? context.engine.scene.getMode() {
      let editMode = context.engine.editor.getEditMode()
      return sceneMode == .video &&
        editMode != .text
    }
    return false
  }

  private var shouldShowFullTimeline: Bool {
    !isMinimized &&
      (!interactor.sheet.isPresented ||
        interactor.sheet.isFloating ||
        interactor.sheet.isReplacing)
  }

  @_spi(Internal) public var body: some View {
    if shouldShowTimeline {
      let currentHeight = !shouldShowFullTimeline
        ? playerBarHeight
        : timelineHeight

      VStack(spacing: 0) {
        VStack(spacing: 0) {
          // Player bar with minimize button
          if let timeline = interactor.timelineProperties.timeline {
            PlayerBarView(isTimelineMinimized: $isMinimized)
              .environmentObject(AnyTimelineInteractor(erasing: interactor))
              .environmentObject(interactor.timelineProperties.player)
              .environmentObject(timeline)
              .frame(height: playerBarHeight)
          }

          // Timeline content (hidden when minimized or sheet is shown)
          if shouldShowFullTimeline {
            TimelineView()
              .environmentObject(AnyTimelineInteractor(erasing: interactor))
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .transition(.move(edge: .bottom).combined(with: .opacity))
          }
        }
        .background {
          Rectangle()
            .fill(colorScheme == .dark
              ? Color(uiColor: .systemBackground)
              : Color(uiColor: .secondarySystemBackground))
        }
        .frame(maxHeight: currentHeight)
        .animation(.imgly.timelineMinimizeMaximize, value: interactor.sheet.isPresented)
      }
      .overlay(alignment: .bottom) {
        // Line between player bar and bottom bar when timeline is collapsed
        Group {
          if isMinimized, interactor.selection == nil {
            Divider()
              .transition(.opacity)
          }
        }
        .animation(.linear, value: interactor.selection)
      }
      .preference(key: BottomPanelIsMinimizedKey.self, value: isMinimized)
    }
  }
}
