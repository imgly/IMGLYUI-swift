import CoreMedia
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

  @State private var lastZoomLevel: CGFloat = 1
  @State var maxVerticalScrollOffset: CGFloat = 0
  @State var overflowWidth: CGFloat = 0

  @State var needsRestoreVerticalOffset = true

  var body: some View {
    let scrollOffsetX = horizontalScrollViewDelegate.contentOffset.x
    let maxPlaybackPoints = timelineProperties.player.maxPlaybackDuration.map { timeline.convertToPoints(time: $0) }
    let isPlayheadStickyToMax = maxPlaybackPoints.map { scrollOffsetX >= $0 } ?? false
    let playheadOffset: CGFloat = if let maxPlaybackPoints, scrollOffsetX >= maxPlaybackPoints {
      maxPlaybackPoints - scrollOffsetX
    } else if horizontalScrollViewDelegate.isDraggingOrDecelerating {
      0
    } else {
      timeline.convertToPoints(time: player.playheadPosition) - scrollOffsetX
    }

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
          .padding(.top, configuration.timelineRulerHeight + configuration.trackSpacing)
          .padding(.bottom, configuration.backgroundTrackHeight + configuration.trackSpacing * 3)
          // Scroll clip into view on selection change.
          .onChange(of: timelineProperties.selectedClip) { newValue in
            guard let id = newValue?.id else { return }
            withAnimation {
              proxy.scrollTo(id)
            }
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
          let maxDuration = timelineProperties.videoDurationConstraints.maximumTime
          let maxOverlayWidth: CGFloat = if let maxDuration,
                                            timeline.totalDuration.seconds > maxDuration.seconds {
            max(0, timeline.totalWidth - timeline.convertToPoints(time: maxDuration))
          } else {
            0
          }
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
    .coordinateSpace(name: "timeline")
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
        let topPadding = configuration.timelineRulerHeight + configuration.trackSpacing
        let bottomPadding = configuration.backgroundTrackHeight + configuration.trackSpacing * 3
        CustomScrollIndicatorView(
          scrollViewFrameHeight: verticalScrollView.bounds.size.height - verticalScrollView.adjustedContentInset
            .top - verticalScrollView.adjustedContentInset.bottom,
          scrollViewContentSizeHeight: verticalScrollView.contentSize.height - topPadding - bottomPadding,
          scrollViewContentOffsetY: verticalScrollView.contentOffset.y,
          scrollViewDelegate: verticalScrollViewDelegate,
          topPadding: configuration.timelineRulerHeight + 3,
          bottomPadding: configuration.backgroundTrackHeight + configuration.trackSpacing * 2 + 3,
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

  /// Restore vertical offset when timeline disappears and reappears in a session.
  /// Set initial vertical position respecting the offsets.
  private func restoreVerticalOffset(_ verticalScrollView: UIScrollView) {
    guard needsRestoreVerticalOffset else { return }
    needsRestoreVerticalOffset = false

    let topInset = configuration.timelineRulerHeight + configuration.trackSpacing
    let bottomInset = configuration.backgroundTrackHeight + configuration.trackSpacing * 3

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

    // Add some delay to "ensure" layouting is done.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.verticalScrollView = verticalScrollView
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
