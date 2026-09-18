import SwiftUI
@_spi(Internal) import IMGLYCore
import IMGLYEngine

/// The timeline component for video editing.
///
/// Place it in the editor's bottom panel. It is also the namespace for everything that customizes
/// it: ``Timeline/Configuration``, ``Timeline/Buttons``, ``Timeline/Item`` and friends.
public struct Timeline: View {
  /// The bottom panel context.
  private let context: BottomPanel.Context
  /// Customizes the timeline's add-content buttons, header, and height.
  private let configuration: Configuration
  /// External control of the expanded/collapsed state, when the integrator provides a binding.
  private let externalIsExpanded: Binding<Bool>?

  @State private var internalIsExpanded = true

  /// Creates a timeline component.
  /// - Parameters:
  ///   - context: The bottom panel context.
  ///   - configuration: Customizes the timeline's add-content buttons, header, and height. The
  ///     defaults render the tracks alone, so declare each surface you need.
  ///   - isExpanded: An optional binding to the timeline's expanded/collapsed state. When provided,
  ///     it sets the initial state and stays in sync as the user or the integrator expands and
  ///     collapses the timeline. When omitted, the timeline manages its own state and starts
  ///     expanded.
  public init(
    context: BottomPanel.Context,
    configuration: Configuration = .init(),
    isExpanded: Binding<Bool>? = nil,
  ) {
    self.context = context
    self.configuration = configuration
    externalIsExpanded = isExpanded
  }

  /// Creates a timeline component with the standard configuration.
  ///
  /// Kept as its own overload rather than relying on the defaults above: an unapplied reference to
  /// `Timeline.init(context:)` does not resolve to an initializer that has extra defaulted
  /// parameters, so removing it would break callers that pass it as a function.
  /// - Parameter context: The bottom panel context.
  public init(context: BottomPanel.Context) {
    self.init(context: context, configuration: .init(), isExpanded: nil)
  }

  @_spi(Internal) public var body: some View {
    TimelineRootView(
      context: context,
      configuration: configuration,
      isExpanded: externalIsExpanded ?? $internalIsExpanded,
    )
  }
}

/// The stateful timeline view. Split from ``Timeline`` so a real `@Binding` drives
/// the expanded/collapsed state — either the integrator's own binding or, by default, the
/// component's internal state.
private struct TimelineRootView: View {
  let context: BottomPanel.Context
  let configuration: Timeline.Configuration
  @Binding var isExpanded: Bool

  @State private var observedTrackCount = 0
  @State private var hasCaptionClips = false
  @EnvironmentObject private var interactor: Interactor

  @Environment(\.imglyTimelineConfiguration) private var timelineConfiguration
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.imglyEditorEnvironment) private var editorEnvironment
  @Environment(\.verticalSizeClass) private var verticalSizeClass

  /// Set when the configured header resolves to no visible items.
  @State private var isHeaderHidden = false

  private let defaultPlayerBarHeight: CGFloat = 56

  /// Zero when the header is empty, so removing every header item removes the bar rather than
  /// leaving an empty strip above the timeline.
  private var playerBarHeight: CGFloat {
    isHeaderHidden ? 0 : defaultPlayerBarHeight
  }

  private func timelineHeight(in context: Timeline.ItemContext?) -> CGFloat {
    if !shouldShowTimeline {
      return 0
    }

    if !isExpanded {
      return playerBarHeight
    }

    let addAudioRow = hasAddAudioRow(in: context)

    switch resolvedHeight(in: context) {
    // A fixed height stays fixed, so the caption lane must not grow it.
    case let .fixed(tracks):
      return height(forTracks: tracks, withCaptionLane: false, withAddAudioRow: addAudioRow)
    case let .dynamic(maximumTracks):
      return height(
        forTracks: min(maximumTracks, observedTrackCount),
        withCaptionLane: hasCaptionClips,
        withAddAudioRow: addAudioRow,
      )
    }
  }

  /// Whether the "Add Audio" button occupies a row in the foreground stack.
  ///
  /// `TimelineContentView` renders no row when the button is removed, hidden, or its `isVisible`
  /// throws, so the height must not reserve one either.
  private func hasAddAudioRow(in context: Timeline.ItemContext?) -> Bool {
    guard let context, let addAudio = configuration.addAudio else { return false }
    return (try? addAudio.isVisible(context)) ?? false
  }

  /// Resolved per render, so the height can follow editor state or the size class. Falls back to
  /// the default when the engine is unavailable or the closure throws, the way the dock resolves
  /// its own layout knobs.
  private func resolvedHeight(in context: Timeline.ItemContext?) -> Timeline.HeightMode {
    guard let context, let height = try? configuration.height(context) else {
      return .dynamic()
    }
    return height
  }

  /// The context every configured ``Timeline/Item`` receives, built once per render of this view
  /// and passed down.
  ///
  /// `ItemContext.make` builds the customer-configured asset library, so it must not run on a view
  /// that observes `Player` — `TimelineContentView` re-renders on every playhead tick. This view
  /// observes the interactor, which does not republish `timelineProperties`.
  private var itemContext: Timeline.ItemContext? {
    .make(
      interactor: interactor,
      editorEnvironment: editorEnvironment,
      verticalSizeClass: verticalSizeClass,
    )
  }

  /// The total timeline height that shows `tracks` overlay tracks, including the player bar, ruler,
  /// background track, and the "Add Audio" row when it is present.
  ///
  /// The caption lane contributes by clip count, not track count: the first caption must grow the
  /// timeline even though its (empty) track already exists. One ordinary row's worth, since it sits
  /// inside the foreground stack rather than in a docked band of its own.
  private func height(
    forTracks tracks: Int,
    withCaptionLane captionLane: Bool,
    withAddAudioRow addAudioRow: Bool,
  ) -> CGFloat {
    let trackHeight = timelineConfiguration.trackHeight
    let backgroundTrackHeight = timelineConfiguration.backgroundTrackHeight
    let trackSpacing = timelineConfiguration.trackSpacing
    let rulerHeight = timelineConfiguration.timelineRulerHeight

    let captionLaneHeight = captionLane ? trackHeight + trackSpacing : 0
    // The extra row is the Add Audio button, which sits in the foreground stack. The background
    // track is the separate `backgroundTrackHeight` term.
    let rows = CGFloat(max(0, tracks) + (addAudioRow ? 1 : 0))
    let tracksHeight = rows * (trackHeight + trackSpacing) + backgroundTrackHeight
      + captionLaneHeight
    return playerBarHeight + tracksHeight + rulerHeight + trackSpacing * 3
  }

  private var shouldShowTimeline: Bool {
    context.engine.editor.getEditMode() != .text
  }

  private var shouldShowFullTimeline: Bool {
    isExpanded &&
      (!interactor.sheet.isPresented ||
        interactor.sheet.isFloating ||
        interactor.sheet.isReplacing)
  }

  var body: some View {
    if shouldShowTimeline {
      let itemContext = itemContext
      let currentHeight = !shouldShowFullTimeline
        ? playerBarHeight
        : timelineHeight(in: itemContext)

      VStack(spacing: 0) {
        VStack(spacing: 0) {
          // Player bar with minimize button
          if let timeline = interactor.timelineProperties.timeline {
            PlayerBarView(
              header: configuration.header,
              headerModifications: configuration.headerModifications,
              itemContext: itemContext,
            )
            .environmentObject(AnyTimelineInteractor(erasing: interactor))
            .environmentObject(interactor.timelineProperties.player)
            .environmentObject(timeline)
            .frame(height: playerBarHeight)
          }

          // Timeline content (hidden when minimized or sheet is shown)
          if shouldShowFullTimeline {
            TimelineView(
              addClip: configuration.addClip,
              addAudio: configuration.addAudio,
              itemContext: itemContext,
            )
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
        // Animate here rather than at the toggle, so the integrator's own writes to the
        // `isExpanded` binding animate too.
        .animation(.imgly.timelineMinimizeMaximize, value: isExpanded)
      }
      .overlay(alignment: .bottom) {
        // Line between player bar and bottom bar when timeline is collapsed
        Group {
          if !isExpanded, interactor.selection == nil {
            Divider()
              .transition(.opacity)
          }
        }
        .animation(.linear, value: interactor.selection)
      }
      .environment(\.imglyTimelineIsExpanded, $isExpanded)
      .onPreferenceChange(TimelineHeaderHiddenKey.self) { isHidden in
        isHeaderHidden = isHidden
      }
      .preference(key: BottomPanelIsMinimizedKey.self, value: !isExpanded)
      .onAppear {
        observedTrackCount = interactor.timelineProperties.dataSource.tracks.count
        hasCaptionClips = interactor.timelineProperties.dataSource.hasCaptionClips
      }
      .onReceive(interactor.timelineProperties.dataSource.$tracks.map(\.count).removeDuplicates()) { tracksCount in
        observedTrackCount = tracksCount
      }
      .onReceive(interactor.timelineProperties.dataSource.$hasCaptionClips.removeDuplicates()) { hasClips in
        hasCaptionClips = hasClips
      }
    }
  }
}

/// The previous name of ``Timeline``.
@available(*, deprecated, renamed: "Timeline", message: "Use 'Timeline' instead.")
public typealias DefaultTimelineComponent = Timeline
