import CoreMedia
import SwiftUI
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

  // We don’t use Introspect’s @Weak property wrapper here because it releases too quickly
  @State private var horizontalScrollView: UIScrollView?
  @State private var verticalScrollView: UIScrollView?
  @State var pinchGestureRecognizer: UIPinchGestureRecognizer?

  @State private var lastZoomLevel: CGFloat = 1
  @State var maxVerticalScrollOffset: CGFloat = 0
  @State var overflowWidth: CGFloat = 0

  @State var needsRestoreVerticalOffset = true

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      ScrollView(.vertical, showsIndicators: false) {
        ScrollViewReader { proxy in
          VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: configuration.trackSpacing) {
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
          // Scroll clip into view on selection change.
          .onChange(of: timelineProperties.selectedClip) { newValue in
            guard let id = newValue?.id else { return }
            withAnimation {
              proxy.scrollTo(id)
            }
          }
        }
      }
      .safeAreaInset(edge: .top, spacing: 0) {
        Rectangle()
          .fill(.clear)
          .frame(height: configuration.timelineRulerHeight + configuration.trackSpacing)
      }
      .safeAreaInset(edge: .bottom, spacing: 0) {
        Rectangle()
          .fill(.clear)
          .frame(height: configuration.backgroundTrackHeight + configuration.trackSpacing * 3)
      }
      .introspect(.scrollView, on: .iOS(.v16...)) { verticalScrollView in
        guard verticalScrollView !== self.verticalScrollView else { return }

        // Delay mutation until the next runloop.
        // https://github.com/siteline/SwiftUI-Introspect/issues/212#issuecomment-1590130815
        DispatchQueue.main.async {
          self.verticalScrollView = verticalScrollView
          verticalScrollView.delegate = verticalScrollViewDelegate
          restoreVerticalOffset()
          verticalScrollView.scrollsToTop = false
        }
      }

      .overlay(alignment: .topLeading) {
        ZStack(alignment: .leading) {
          HStack(spacing: 0) {
            Rectangle()
              .fill(colorScheme == .dark
                ? Color(uiColor: .systemBackground)
                : Color(uiColor: .secondarySystemBackground)).frame(width: viewportWidth)
              .padding(.leading, -viewportWidth / 2)
              .background(Color(uiColor: .secondarySystemBackground))
            Rectangle()
              .fill(.bar)
              .frame(width: timeline.totalWidth)
            Rectangle()
              .fill(colorScheme == .dark
                ? Color(uiColor: .systemBackground)
                : Color(uiColor: .secondarySystemBackground))
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
          Rectangle()
            .fill(colorScheme == .dark
              ? Color(uiColor: .systemBackground)
              : Color(uiColor: .secondarySystemBackground))
            .frame(height: configuration.backgroundTrackHeight + configuration.trackSpacing * 2)
          TrackView(track: dataSource.backgroundTrack)
            .frame(height: configuration.backgroundTrackHeight)
            .background(alignment: .trailing) {
              BackgroundTrackAddButton()
                .alignmentGuide(.trailing) { _ in 0 }
            }
            .padding(.horizontal, viewportWidth / 2)
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
            action: #selector(TimelinePinchGestureRecognizerDelegate.pinched(_:))
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
        CustomScrollIndicatorView(
          scrollViewFrameHeight: verticalScrollView.frame.height,
          scrollViewContentSizeHeight: verticalScrollView.contentSize.height,
          scrollViewContentOffsetY: verticalScrollView.contentOffset.y,
          scrollViewDelegate: verticalScrollViewDelegate,
          topPadding: 3 + configuration.timelineRulerHeight,
          bottomPadding: 3 + configuration.backgroundTrackHeight + configuration.trackSpacing * 2
        )
      }
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
        }
    )

    .onChange(of: pinchDelegate.scale) { newValue in
      guard timeline.isPinchingZoom else { return }

      timeline.setZoomLevel(newValue * lastZoomLevel)
      // After zooming, restore the playhead position on the zoomed scale.
      // This may create an imprecision due to rounding errors.
      // To reproduce, select a clip with a precise length (e.g. 20 seconds) and
      // scroll the timeline to snap to the clip’s end. Then zoom in and out and
      // you will see rounding errors like 19.999333333333333 seconds.
      // We should pin the time offset somehow, but this doesn’t currently
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
        timeline.interactor?.refreshThumbnails()
      }
    }

    .onChange(of: player.playheadPosition) { _ in
      guard !horizontalScrollViewDelegate.isDraggingOrDecelerating else { return }
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
      if horizontalScrollViewDelegate.isDraggingOrDecelerating {
        let time = timeline.convertToTime(points: newValue.x)
        timeline.interactor?.setPlayheadPosition(time)
      }
    }

    .onChange(of: verticalScrollViewDelegate.contentOffset) { newValue in
      guard !needsRestoreVerticalOffset else { return }
      timeline.verticalScrollOffset = newValue.y
    }
  }

  /// Update scroll view offset from playhead position
  private func updateHorizontalOffset() {
    guard let horizontalScrollView else { return }
    let contentOffsetX = timeline.convertToPoints(time: player.playheadPosition)
    let contentOffset = CGPoint(x: contentOffsetX, y: 0)
    horizontalScrollView.setContentOffset(contentOffset, animated: false)
  }

  /// Restore vertical offset when timeline disappears and reappears ins a session.
  /// Set initial vertical position respecting the offsets.
  private func restoreVerticalOffset() {
    guard needsRestoreVerticalOffset else { return }
    needsRestoreVerticalOffset = false

    guard let verticalScrollView else { return }
    let contentOffsetY: CGFloat

    if timeline.needsInitialScrollOffset {
      timeline.needsInitialScrollOffset = false
      // Scroll to bottom
      let bottomInset = configuration.backgroundTrackHeight + configuration.trackSpacing * 3
      contentOffsetY = verticalScrollView.contentSize.height
        - verticalScrollView.frame.height
        + bottomInset
      timeline.verticalScrollOffset = contentOffsetY
    } else {
      contentOffsetY = timeline.verticalScrollOffset
    }

    let contentOffset = CGPoint(x: 0, y: contentOffsetY)
    verticalScrollView.setContentOffset(contentOffset, animated: false)
  }
}

private struct TimelineOverflowSizeKey: PreferenceKey {
  static var defaultValue: CGFloat = .zero
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value += nextValue()
  }
}
