import CoreMedia
import IMGLYEngine
import SwiftUI
@_spi(Internal) import IMGLYCore
@_spi(Advanced) import SwiftUIIntrospect
import UIKit

struct TimelineContentView: View {
  @EnvironmentObject var player: Player
  @EnvironmentObject var timeline: Timeline
  @EnvironmentObject var timelineProperties: TimelineProperties
  @EnvironmentObject var dataSource: TimelineDataSource
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.imglyTimelineConfiguration) var configuration: TimelineConfiguration
  @Environment(\.imglyViewportWidth) var viewportWidth: CGFloat

  @StateObject private var horizontalScrollViewDelegate = TimelineScrollViewDelegate()
  @StateObject private var verticalScrollViewDelegate = TimelineScrollViewDelegate()
  @StateObject private var pinchDelegate = TimelinePinchGestureRecognizerDelegate()

  @State private var shouldContinuePlayingAfterDraggingEnded = false

  // We don't use Introspect's @Weak property wrapper here because it releases too quickly
  @State private var horizontalScrollView: UIScrollView?
  @State private var verticalScrollView: UIScrollView?
  @State var pinchGestureRecognizer: UIPinchGestureRecognizer?

  @State private var dragAutoScrollTask: Task<Void, Never>?

  // Hand-tuned on iPhone 17 Pro — adjust if drag-edge auto-scroll feels too eager / sluggish.
  private let dragAutoScrollThreshold: CGFloat = 48
  private let dragAutoScrollBaseSpeed: CGFloat = 3
  private let dragAutoScrollDistanceMultiplier: CGFloat = 0.2

  @State private var lastZoomLevel: CGFloat = 1
  @State var overflowWidth: CGFloat = 0

  @State var needsRestoreVerticalOffset = true

  /// "+ Add Clip" button anchor. Sums UI clip durations + trim/drop preview
  /// deltas instead of using `timeline.totalDuration` so the anchor follows
  /// in-flight drop previews before the engine updates page duration.
  private var backgroundTrackEndPoints: CGFloat {
    let hasClips = !dataSource.backgroundTrack.clips.isEmpty
    let dropDelta = previewDropDurationIntoBackground
    let hasDropPreview = dropDelta > .zero
    guard hasClips || hasDropPreview else { return 0 }

    let packedLength = dataSource.backgroundTrack.clips
      .compactMap(\.duration)
      .reduce(CMTime.zero, +)
    let liveEnd = packedLength + timelineProperties.backgroundTrackTrimDelta + dropDelta
    return timeline.convertToPoints(time: max(.zero, liveEnd))
  }

  /// The opaque chrome fill behind the ruler and the pinned lanes.
  private var timelineChromeColor: SwiftUI.Color {
    colorScheme == .dark ? Color(uiColor: .systemBackground) : Color(uiColor: .secondarySystemBackground)
  }

  /// Top inset above the foreground track stack: just the ruler. The caption lane is a row inside the
  /// stack, so it needs no reserved band.
  private var verticalTopInset: CGFloat {
    configuration.timelineRulerHeight + configuration.trackSpacing
  }

  /// Dragged clip's duration during a foreground→background drop preview.
  /// Zero for within-bg reorder (length unchanged) and idle states.
  private var previewDropDurationIntoBackground: CMTime {
    guard case let .dragging(context) = timelineProperties.dragDropState,
          case let .existingTrack(trackID, _, _, _) = context.dropTarget,
          trackID == dataSource.backgroundTrack.id,
          let clip = dataSource.findClip(id: context.clipID),
          !clip.isInBackgroundTrack,
          let duration = clip.duration else {
      return .zero
    }
    return duration
  }

  var body: some View {
    let scrollOffsetX = horizontalScrollViewDelegate.contentOffset.x
    let isVoiceOverRecordModeRecording = timeline.interactor?.isVoiceOverRecordModeRecording == true
    let maxPlaybackPoints = timelineProperties.player.maxPlaybackDuration.map { timeline.convertToPoints(time: $0) }
    let isPlayheadStickyToMax = maxPlaybackPoints.map { scrollOffsetX >= $0 } ?? false
    let isClipDragging = if case .dragging = timelineProperties.dragDropState {
      true
    } else {
      false
    }
    let playheadOffset: CGFloat = if let maxPlaybackPoints, scrollOffsetX >= maxPlaybackPoints {
      maxPlaybackPoints - scrollOffsetX
    } else if horizontalScrollViewDelegate.isDraggingOrDecelerating || isClipDragging {
      0
    } else {
      timeline.convertToPoints(time: player.playheadPosition) - scrollOffsetX
    }

    ScrollView(.horizontal, showsIndicators: false) {
      ScrollView(.vertical, showsIndicators: false) {
        ScrollViewReader { proxy in
          VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: configuration.trackSpacing) {
              // Topmost, and scrolls with the rest — matching web, where the caption lane is an ordinary
              // foreground row. Its position here is load-bearing: the drop hit test treats "above the
              // caption row's bottom edge" as the caption lane, which holds only while it is drawn first.
              if dataSource.hasCaptionClips {
                TrackView(track: dataSource.captionTrack)
                  .frame(height: configuration.trackHeight)
              }
              ForEach(dataSource.tracks.reversed(), id: \.self) { track in
                TrackView(track: track)
                  .frame(height: configuration.trackHeight)
              }
              AddAudioButton()
            }
            .background {
              // Measure the width of all contained clips, including the overflow.
              GeometryReader { geometry in
                Color.clear
                  .preference(key: TimelineOverflowSizeKey.self, value: geometry.size.width)
              }
            }
            .onPreferenceChange(TimelineOverflowSizeKey.self) { width in
              overflowWidth = width
            }
            .padding(.horizontal, viewportWidth / 2)
            .padding(.trailing, -(overflowWidth - (timeline.totalWidth)))
          }
          .frame(width: timeline.totalWidth + viewportWidth)
          .padding(.top, verticalTopInset)
          .padding(.bottom, configuration.foregroundStackBottomInset)
          // Scroll clip into view on selection change.
          .onChange(of: timelineProperties.selectedClip) { newValue in
            guard let id = newValue?.id else { return }
            withAnimation {
              proxy.scrollTo(id)
            }
          }
          .onChange(of: timelineProperties.scrollTargetRequest) { newValue in
            guard let request = newValue else { return }
            scrollToRequestedClip(request, proxy: proxy)
          }
          .onReceive(dataSource.$tracks) { _ in
            guard let request = timelineProperties.scrollTargetRequest else { return }
            scrollToRequestedClip(request, proxy: proxy)
          }
        }
      }
      .introspect(.scrollView, on: .iOS(.v16...)) { verticalScrollView in
        guard verticalScrollView !== self.verticalScrollView, needsRestoreVerticalOffset else { return }

        // Delay mutation until the next runloop.
        // https://github.com/siteline/SwiftUI-Introspect/issues/212#issuecomment-1590130815
        DispatchQueue.main.async {
          verticalScrollView.delegate = verticalScrollViewDelegate
          verticalScrollView.scrollsToTop = false
          restoreVerticalOffset(verticalScrollView)
        }
      }
      .overlay(alignment: .topLeading) {
        ZStack(alignment: .leading) {
          HStack(spacing: 0) {
            Rectangle()
              .fill(timelineChromeColor).frame(width: viewportWidth)
              .padding(.leading, -viewportWidth / 2)
              .background(Color(uiColor: .secondarySystemBackground))
            Rectangle()
              .fill(.bar)
              .frame(width: timeline.totalWidth)
            Rectangle()
              .fill(timelineChromeColor)
              .frame(width: viewportWidth)
              .padding(.trailing, -viewportWidth / 2)
              .background(Color(uiColor: .secondarySystemBackground))
          }

          TimelineRulerView()
            .padding(.horizontal, viewportWidth / 2)
        }
        .frame(height: configuration.timelineRulerHeight)
        .allowsHitTesting(false)
      }
      .overlay(alignment: .bottomLeading) {
        ZStack(alignment: .leading) {
          let maxDuration = timelineProperties.videoDurationConstraints.maximumTime
          let maxOverlayWidth: CGFloat = if let maxDuration,
                                            timeline.totalDuration.seconds > maxDuration.seconds {
            max(0, timeline.totalWidth - timeline.convertToPoints(time: maxDuration))
          } else {
            0
          }
          Rectangle()
            .fill(timelineChromeColor)
            .frame(height: configuration.backgroundLaneOverlayHeight)
          // Placed before `TrackView` in the ZStack so trim handles (which extend
          // past the last clip's right edge) render on top of the button.
          BackgroundTrackAddButton()
            .frame(height: configuration.backgroundTrackHeight)
            .padding(.leading, viewportWidth / 2 + backgroundTrackEndPoints)
          TrackView(track: dataSource.backgroundTrack)
            .frame(height: configuration.backgroundTrackHeight)
            .padding(.horizontal, viewportWidth / 2)
          if maxOverlayWidth > 0,
             let maxDuration {
            let overlayColor = colorScheme == .dark
              ? Color(uiColor: .systemBackground).opacity(0.6)
              : Color(uiColor: .secondarySystemBackground).opacity(0.8)
            Rectangle()
              .fill(overlayColor)
              .frame(width: maxOverlayWidth, height: configuration.backgroundTrackHeight)
              .clipShape(TrailingRoundedRectangle(radius: configuration.cornerRadius))
              .offset(x: timeline.convertToPoints(time: maxDuration) + viewportWidth / 2)
              .zIndex(1)
              .allowsHitTesting(false)
          }
        }
        .overlay(alignment: .top) {
          // Line above background track
          Divider()
            .padding(.horizontal, -viewportWidth / 2)
        }
      }
      // Snapping indicator lines
      .overlay(alignment: .leading) {
        ForEach(Array(zip(timeline.snapIndicatorLinePositions.indices, timeline.snapIndicatorLinePositions)),
                id: \.0) { _, position in
          SnapIndicatorLineView()
            .offset(x: timeline.convertToPoints(time: position) + viewportWidth / 2)
            .foregroundColor(configuration.timelineSnapIndicatorColor)
            .padding(.top, configuration.timelineRulerHeight)
            .padding(.bottom, -configuration.trackSpacing * 1.5)
        }
      }
    }
    // Mounted on the outer scroll view so the preference merges contributions from
    // both foreground tracks and the background-track overlay below.
    .onPreferenceChange(TrackFramesPreferenceKey.self) { frames in
      if timelineProperties.trackFrames != frames {
        timelineProperties.trackFrames = frames
      }
    }
    .coordinateSpace(name: "timeline")
    .allowsHitTesting(!isVoiceOverRecordModeRecording)
    .introspect(.scrollView, on: .iOS(.v16...)) { horizontalScrollView in
      guard horizontalScrollView !== self.horizontalScrollView else { return }

      // Delay mutation until the next runloop.
      // https://github.com/siteline/SwiftUI-Introspect/issues/212#issuecomment-1590130815
      DispatchQueue.main.async {
        horizontalScrollView.delegate = horizontalScrollViewDelegate
        self.horizontalScrollView = horizontalScrollView
        updateHorizontalOffset()

        if pinchGestureRecognizer == nil {
          pinchGestureRecognizer = UIPinchGestureRecognizer(
            target: pinchDelegate,
            action: #selector(TimelinePinchGestureRecognizerDelegate.pinched(_:)),
          )
        }
        if let pinchGestureRecognizer {
          pinchGestureRecognizer.delegate = pinchDelegate
          horizontalScrollView.addGestureRecognizer(pinchGestureRecognizer)
        }
      }
    }

    .overlay(alignment: .topTrailing) {
      if let verticalScrollView {
        let topPadding = verticalTopInset
        let bottomPadding = configuration.foregroundStackBottomInset
        CustomScrollIndicatorView(
          scrollViewFrameHeight: verticalScrollView.bounds.size.height - verticalScrollView.adjustedContentInset
            .top - verticalScrollView.adjustedContentInset.bottom,
          scrollViewContentSizeHeight: verticalScrollView.contentSize.height - topPadding - bottomPadding,
          scrollViewContentOffsetY: verticalScrollView.contentOffset.y,
          scrollViewDelegate: verticalScrollViewDelegate,
          topPadding: configuration.timelineRulerHeight + 3,
          bottomPadding: configuration.backgroundLaneOverlayHeight + 3,
        )
      }
    }

    .overlay {
      TimelineDurationConstraintsView(
        scrollOffset: scrollOffsetX,
        showMaxTooltipWhileSticky: isPlayheadStickyToMax,
      )
    }

    .overlay {
      // Playhead marker line
      let isSnappingToPlayhead = timeline.snapIndicatorLinePositions.contains(player.playheadPosition)
      RoundedRectangle(cornerRadius: 1)
        .fill(isSnappingToPlayhead
          ? configuration.timelineSnapIndicatorColor
          : configuration.playheadColor)
        .frame(width: isSnappingToPlayhead ? 2 : 1)
        .allowsHitTesting(false)
        .background {
          RoundedRectangle(cornerRadius: 3)
            .inset(by: -1)
            .fill(Color.black.opacity(0.1))
        }
        .offset(x: playheadOffset)
        .padding(.top, configuration.timelineRulerHeight - 1)
        .padding(.bottom, 1)
    }

    .task {
      lastZoomLevel = timeline.zoomLevel
    }

    .gesture(
      TapGesture(count: 1)
        .onEnded { _ in
          timeline.interactor?.deselect()
        },
    )

    .onChange(of: pinchDelegate.scale) { newValue in
      guard timeline.isPinchingZoom else { return }

      timeline.setZoomLevel(newValue * lastZoomLevel)
      // After zooming, restore the playhead position on the zoomed scale.
      // This may create an imprecision due to rounding errors.
      // To reproduce, select a clip with a precise length (e.g. 20 seconds) and
      // scroll the timeline to snap to the clip's end. Then zoom in and out and
      // you will see rounding errors like 19.999333333333333 seconds.
      // We should pin the time offset somehow, but this doesn't currently
      // work due to how the values are propagated; the scrollOffset is always
      // converted back to a timecode when it changes, which will be imprecise
      // depending on the current zoom level.
      let contentOffsetX = timeline.convertToPoints(time: player.playheadPosition)
      let contentOffset = CGPoint(x: contentOffsetX, y: 0)
      horizontalScrollView?.setContentOffset(contentOffset, animated: false)
    }

    .onChange(of: pinchDelegate.state) { newValue in
      switch newValue {
      case .began:
        timeline.isPinchingZoom = true
      case .changed:
        break
      default:
        lastZoomLevel = timeline.zoomLevel
        timeline.isPinchingZoom = false
        timeline.interactor?.refreshZoomDependentThumbnails()
      }
    }

    .onChange(of: player.playheadPosition) { _ in
      guard !horizontalScrollViewDelegate.isDraggingOrDecelerating else { return }
      // Auto-scroll owns the scroll position during a clip drag — running
      // updateHorizontalOffset here would feedback-loop with `tickAutoScroll`.
      if case .dragging = timelineProperties.dragDropState {
        return
      }
      updateHorizontalOffset()
    }

    .onChange(of: horizontalScrollViewDelegate.isDraggingOrDecelerating) { newValue in
      if newValue {
        shouldContinuePlayingAfterDraggingEnded = player.isPlaying
        timeline.interactor?.pause()
      } else if shouldContinuePlayingAfterDraggingEnded,
                player.playheadPosition < timeline.totalDuration {
        timeline.interactor?.play()
        shouldContinuePlayingAfterDraggingEnded = false
      }
    }

    .onChange(of: horizontalScrollViewDelegate.contentOffset) { newValue in
      let isClipDragging = if case .dragging = timelineProperties.dragDropState {
        true
      } else {
        false
      }
      if horizontalScrollViewDelegate.isDraggingOrDecelerating || isClipDragging {
        let time = timeline.convertToTime(points: newValue.x)
        timeline.interactor?.setPlayheadPosition(time)
      }
      if timelineProperties.horizontalScrollOffsetPoints != newValue.x {
        timelineProperties.horizontalScrollOffsetPoints = newValue.x
      }
    }

    .onChange(of: verticalScrollViewDelegate.contentOffset) { newValue in
      guard !needsRestoreVerticalOffset else { return }
      timeline.verticalScrollOffset = newValue.y
    }

    .onChange(of: timelineProperties.dragDropState) { newState in
      updateDragAutoScroll(for: newState)
    }

    // Defensive: if the editor sheet dismisses mid-drag the dragDropState change
    // wouldn't fire, leaving the auto-scroll task spinning until it next reads state.
    .onDisappear {
      dragAutoScrollTask?.cancel()
      dragAutoScrollTask = nil
    }
  }

  /// Starts/stops a 60Hz tick that scrolls when the drag pointer is within
  /// `dragAutoScrollThreshold` of an edge, at a speed proportional to overshoot.
  private func updateDragAutoScroll(for state: DragDropState) {
    guard case let .dragging(context) = state,
          horizontalScrollView != nil || verticalScrollView != nil else {
      dragAutoScrollTask?.cancel()
      dragAutoScrollTask = nil
      return
    }
    if dragAutoScrollTask != nil {
      return
    } // task re-reads state each tick
    let clipID = context.clipID
    let draggedClipIsCaption = dataSource.findClip(id: clipID)?.clipType == .caption
    dragAutoScrollTask = Task { @MainActor in
      while !Task.isCancelled {
        guard case let .dragging(context) = timelineProperties.dragDropState,
              context.clipID == clipID else { break }
        let pointer = context.currentTouchLocation

        let horizontalScrolled = tickAutoScroll(
          scrollView: horizontalScrollView,
          pointer: pointer,
          axis: .horizontal,
        )
        // The background row is pinned at the viewport's bottom edge, so any
        // drag inside or below it would otherwise sit in the auto-scroll
        // zone and pull the foreground tracks off-screen. Suppress vertical
        // scroll for everything from the bg row's top edge downward; scroll
        // resumes when the user moves back up into the foreground area.
        // Same for the caption lane at the top; caption drags never scroll vertically.
        let pointerInBackgroundLane: Bool = {
          guard let bgFrame = timelineProperties.trackFrames[dataSource.backgroundTrack.id] else {
            return false
          }
          return pointer.y >= bgFrame.minY
        }()
        let pointerInCaptionLane: Bool = {
          guard dataSource.hasCaptionClips,
                let captionFrame = timelineProperties.trackFrames[dataSource.captionTrack.id] else {
            return false
          }
          return pointer.y <= captionFrame.maxY
        }()
        let verticalScrolled = !pointerInBackgroundLane && !pointerInCaptionLane
          && !draggedClipIsCaption && tickAutoScroll(
            scrollView: verticalScrollView,
            pointer: pointer,
            axis: .vertical,
          )

        if !horizontalScrolled, !verticalScrolled {
          break
        }

        try? await Task.sleep(nanoseconds: 16_666_666) // ~60fps
      }
      dragAutoScrollTask = nil
    }
  }

  /// Returns `true` if the offset was actually updated (pointer in edge zone and
  /// scroll has headroom).
  private func tickAutoScroll(
    scrollView: UIScrollView?,
    pointer: CGPoint,
    axis: Axis,
  ) -> Bool {
    guard let scrollView else { return false }
    // `superview.convert` gives the viewport's window frame independent of the scroll
    // view's content offset (`scrollView.bounds` would shift with the current scroll).
    let frame = scrollView.superview?.convert(scrollView.frame, to: nil) ?? scrollView.frame
    // Inset by the adjusted content insets so docked overlays (ruler, background track)
    // don't count as empty drop zones for edge detection.
    let insets = scrollView.adjustedContentInset
    let pointerCoord = axis == .horizontal ? pointer.x : pointer.y
    let minEdge = axis == .horizontal ? frame.minX + insets.left : frame.minY + insets.top
    let maxEdge = axis == .horizontal ? frame.maxX - insets.right : frame.maxY - insets.bottom
    let currentOffset = axis == .horizontal ? scrollView.contentOffset.x : scrollView.contentOffset.y
    // Include the trailing inset so auto-scroll can push past edge-docked overlays —
    // UIScrollView's scrollable range extends into the inset region.
    let maxOffset: CGFloat = if axis == .horizontal {
      max(0, scrollView.contentSize.width - scrollView.bounds.width + insets.right)
    } else {
      max(0, scrollView.contentSize.height - scrollView.bounds.height + insets.bottom)
    }

    let distanceFromMin = pointerCoord - minEdge
    let distanceFromMax = maxEdge - pointerCoord

    var speed: CGFloat = 0
    if distanceFromMin < dragAutoScrollThreshold {
      let overshoot = max(0, dragAutoScrollThreshold - distanceFromMin)
      speed = -(dragAutoScrollBaseSpeed + overshoot * dragAutoScrollDistanceMultiplier)
    } else if distanceFromMax < dragAutoScrollThreshold {
      let overshoot = max(0, dragAutoScrollThreshold - distanceFromMax)
      speed = dragAutoScrollBaseSpeed + overshoot * dragAutoScrollDistanceMultiplier
    }

    if speed == 0 {
      return false
    }

    let proposed = currentOffset + speed
    let clamped = max(0, min(maxOffset, proposed))
    if clamped == currentOffset {
      return false
    }

    if axis == .horizontal {
      scrollView.contentOffset.x = clamped
    } else {
      scrollView.contentOffset.y = clamped
    }
    return true
  }

  private func updateHorizontalOffset() {
    guard let horizontalScrollView else { return }
    let contentOffsetX = timeline.convertToPoints(time: player.playheadPosition)
    let contentOffset = CGPoint(x: contentOffsetX, y: 0)
    horizontalScrollView.setContentOffset(contentOffset, animated: false)
  }

  /// Restore vertical offset when the timeline disappears and reappears in a session.
  /// Set initial vertical position respecting the offsets.
  private func restoreVerticalOffset(_ verticalScrollView: UIScrollView) {
    guard needsRestoreVerticalOffset else { return }
    needsRestoreVerticalOffset = false

    let topInset = verticalTopInset
    let bottomInset = configuration.foregroundStackBottomInset

    verticalScrollView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
    verticalScrollView.layoutIfNeeded()

    let contentOffsetY: CGFloat

    if timeline.needsInitialScrollOffset {
      timeline.needsInitialScrollOffset = false
      let totalContentHeight = verticalScrollView.contentSize.height
      let visibleHeight = verticalScrollView.bounds.size.height

      // iOS 16 seems to handle this differently than iOS 17 and iOS 18.
      // For iOS 16 it is enough to set the correct contentInset.
      if #available(iOS 17.0, *) {
        contentOffsetY = totalContentHeight - visibleHeight + verticalScrollView.adjustedContentInset.bottom
      } else {
        contentOffsetY = totalContentHeight - visibleHeight
      }
      timeline.verticalScrollOffset = contentOffsetY
    } else {
      contentOffsetY = timeline.verticalScrollOffset
    }

    let contentOffset = CGPoint(x: 0, y: contentOffsetY)
    verticalScrollView.setContentOffset(contentOffset, animated: false)

    self.verticalScrollView = verticalScrollView
    // Hopped, and passed the scroll view explicitly: the `@State` writes here are not guaranteed to be
    // visible in this same turn, so introspection can run this body again and re-apply the restored
    // offset. Revealing afterwards keeps the reveal last.
    DispatchQueue.main.async {
      applyPendingScrollRequest(in: verticalScrollView)
    }
  }

  private func scrollToRequestedClip(_ request: TimelineScrollTargetRequest, proxy: ScrollViewProxy) {
    guard dataSource.findClip(id: request.id) != nil else { return }
    // `ScrollViewReader` spans both axes, so `scrollTo` scrubs the timeline in time as well as revealing
    // the row — wanted when the user navigates to a clip, not when a closing sheet reveals one.
    if !request.isVerticalOnly {
      withAnimation {
        proxy.scrollTo(request.id)
      }
    }
    // Hopped off the update pass: consuming the request publishes, which SwiftUI forbids from inside its
    // own body evaluation. It also lets `scrollTo`'s own vertical move land before we correct it.
    DispatchQueue.main.async {
      applyPendingScrollRequest()
    }
  }

  /// Reveals the pending request's row and consumes it. Stays pending while the scroll view has not been
  /// introspected yet or the clip has no displayed row; `restoreVerticalOffset` and the `$tracks`
  /// observer retry it then.
  private func applyPendingScrollRequest(in scrollView: UIScrollView? = nil) {
    guard let request = timelineProperties.scrollTargetRequest,
          let scrollView = scrollView ?? verticalScrollView,
          let index = displayedTrackIndex(ofClip: request.id) else { return }
    revealRow(atIndex: index, in: scrollView)
    timelineProperties.consumeScrollRequest(request)
  }

  /// Scrolls the row at `index` clear of the ruler and of the pinned background lane, from whichever
  /// side it is hidden on.
  private func revealRow(atIndex index: Int, in scrollView: UIScrollView) {
    let rowTop = verticalTopInset + CGFloat(index) * (configuration.trackHeight + configuration.trackSpacing)
    let breathingRoom = configuration.trackSpacing
    // Both are overlays painted over the scrolling content, so they are what actually hides a row;
    // `contentInset` is scroll slack and hides nothing.
    let clearOfRuler = rowTop - configuration.timelineRulerHeight - breathingRoom
    let clearOfBackgroundLane = rowTop + configuration.trackHeight
      + configuration.backgroundLaneOverlayHeight + breathingRoom - scrollView.bounds.height
    // `min` last so a viewport too short to fit the row — which is what a closing sheet leaves behind
    // while the timeline springs back to full height — resolves to top-aligning. That reveals the row
    // without depending on the height being settled, so a single pass is enough.
    let revealing = min(clearOfRuler, max(clearOfBackgroundLane, scrollView.contentOffset.y))

    let minOffsetY = -scrollView.adjustedContentInset.top
    let maxOffsetY = max(minOffsetY, scrollView.contentSize.height
      + scrollView.adjustedContentInset.bottom - scrollView.bounds.height)
    let targetY = min(max(revealing, minOffsetY), maxOffsetY)

    guard abs(scrollView.contentOffset.y - targetY) > 1 else { return }
    // Not animated: the timeline is usually still sliding up around this, and UIScrollView re-clamps its
    // offset as the bounds change, cutting the animation short.
    scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: targetY), animated: false)
  }

  /// Index of the row that draws `clipID`. Must mirror the row order `body` draws — caption lane first,
  /// then the reversed foreground tracks — because the index is turned into a Y offset above.
  private func displayedTrackIndex(ofClip clipID: DesignBlockID) -> Int? {
    var displayedTracks = Array(dataSource.tracks.reversed())
    if dataSource.hasCaptionClips {
      displayedTracks.insert(dataSource.captionTrack, at: 0)
    }
    return displayedTracks.firstIndex { track in
      track.clips.contains { $0.id == clipID }
    }
  }
}

private struct TimelineOverflowSizeKey: PreferenceKey {
  static let defaultValue: CGFloat = .zero
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value += nextValue()
  }
}

private struct TrailingRoundedRectangle: Shape {
  let radius: CGFloat

  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: [.topRight, .bottomRight],
      cornerRadii: CGSize(width: radius, height: radius),
    )
    return Path(path.cgPath)
  }
}
