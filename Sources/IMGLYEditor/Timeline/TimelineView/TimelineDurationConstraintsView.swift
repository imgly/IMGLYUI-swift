import CoreMedia
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

struct TimelineDurationConstraintsView: View {
  @EnvironmentObject var timeline: Timeline
  @EnvironmentObject var timelineProperties: TimelineProperties
  @Environment(\.imglyTimelineConfiguration) private var configuration: TimelineConfiguration
  @Environment(\.imglyViewportWidth) private var viewportWidth: CGFloat

  let scrollOffset: CGFloat
  let showMaxTooltipWhileSticky: Bool

  @State private var showMaxTooltip = false
  @State private var wasAtOrAboveMax = false
  @State private var minTooltipWidth: CGFloat = 0
  @State private var maxTooltipWidth: CGFloat = 0
  @State private var maxTooltipTask: Task<Void, Never>?

  private struct MaxTooltipTaskID: Equatable {
    let totalSeconds: Double
    let maxSeconds: Double
  }

  var body: some View {
    let constraints = timelineProperties.videoDurationConstraints
    let minDuration = constraints.minimumTime
    let maxDuration = constraints.maximumTime

    if minDuration == nil, maxDuration == nil {
      EmptyView()
    } else {
      ZStack(alignment: .topLeading) {
        let totalDuration = timeline.totalDuration
        let baseOffset = viewportWidth / 2
        let lineWidth: CGFloat = 1
        let isBelowMin = minDuration.map { totalDuration.seconds < $0.seconds } ?? false
        let isAboveMax = maxDuration.map { totalDuration.seconds > $0.seconds } ?? false
        let showMinLine = isBelowMin
        let showMaxLine = isAboveMax || showMaxTooltip || showMaxTooltipWhileSticky
        let showMaxTooltipActual = showMaxTooltip || showMaxTooltipWhileSticky

        if let minDuration, minDuration.seconds > 0 {
          let minRawX = baseOffset + timeline.convertToPoints(time: minDuration)
          let minX = clampIndicatorX(minRawX - scrollOffset, lineWidth: lineWidth)
          let minTooltipCenterX = clampTooltipCenterX(minX, width: minTooltipWidth)

          if showMinLine {
            ConstraintLine(color: .red)
              .frame(width: lineWidth)
              .offset(x: minX)
          }

          ConstraintTooltip(
            text: .imgly.localized("ly_img_editor_timeline_video_length_too_short"),
            backgroundColor: .red,
            textColor: .white,
            isVisible: isBelowMin,
          )
          .readWidth($minTooltipWidth)
          .frame(height: configuration.timelineRulerHeight, alignment: .center)
          .offset(x: minTooltipCenterX - minTooltipWidth / 2)
        }

        if let maxDuration, maxDuration.seconds > 0 {
          let maxRawX = baseOffset + timeline.convertToPoints(time: maxDuration)
          let maxX = clampIndicatorLeft(maxRawX - scrollOffset)
          let maxTooltipCenterX = clampTooltipCenterLeft(maxX, width: maxTooltipWidth)

          if showMaxLine {
            ConstraintLine(color: Color(uiColor: .secondaryLabel))
              .frame(width: lineWidth)
              .offset(x: maxX)
          }

          ConstraintTooltip(
            text: .imgly.localized("ly_img_editor_timeline_maximum_video_length"),
            backgroundColor: Color(uiColor: .label),
            textColor: Color(uiColor: .systemBackground),
            isVisible: showMaxTooltipActual,
          )
          .readWidth($maxTooltipWidth)
          .frame(height: configuration.timelineRulerHeight, alignment: .center)
          .offset(x: maxTooltipCenterX - maxTooltipWidth / 2)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .allowsHitTesting(false)
      .task(
        id: MaxTooltipTaskID(
          totalSeconds: timeline.totalDuration.seconds,
          maxSeconds: maxDuration?.seconds ?? 0,
        ),
      ) {
        updateMaxTooltip(totalDuration: timeline.totalDuration, maxDuration: maxDuration)
      }
    }
  }

  private func clampIndicatorX(_ rawX: CGFloat, lineWidth: CGFloat) -> CGFloat {
    min(max(0, rawX), max(0, viewportWidth - lineWidth))
  }

  private func clampIndicatorLeft(_ rawX: CGFloat) -> CGFloat {
    max(0, rawX)
  }

  private func clampTooltipCenterX(_ rawX: CGFloat, width: CGFloat) -> CGFloat {
    guard width > 0 else { return rawX }
    let half = width / 2
    let minCenter = half
    let maxCenter = max(minCenter, viewportWidth - half)
    return min(max(rawX, minCenter), maxCenter)
  }

  private func clampTooltipCenterLeft(_ rawX: CGFloat, width: CGFloat) -> CGFloat {
    guard width > 0 else { return rawX }
    let half = width / 2
    return rawX < half ? half : rawX
  }

  private func updateMaxTooltip(totalDuration: CMTime, maxDuration: CMTime?) {
    maxTooltipTask?.cancel()

    guard let maxDuration, maxDuration.seconds > 0 else {
      showMaxTooltip = false
      wasAtOrAboveMax = false
      return
    }

    let isAtOrAboveMax = totalDuration.seconds >= maxDuration.seconds
    if isAtOrAboveMax, !wasAtOrAboveMax {
      showMaxTooltip = true
      maxTooltipTask = Task {
        try? await Task.sleep(for: .milliseconds(1500))
        if !Task.isCancelled {
          showMaxTooltip = false
        }
      }
    } else if !isAtOrAboveMax {
      showMaxTooltip = false
    }

    wasAtOrAboveMax = isAtOrAboveMax
  }
}

private struct ConstraintTooltip: View {
  let text: LocalizedStringResource
  let backgroundColor: Color
  let textColor: Color
  let isVisible: Bool

  var body: some View {
    Text(text)
      .font(.caption2)
      .foregroundColor(textColor)
      .padding(.horizontal, 6)
      .frame(minHeight: 16)
      .background(backgroundColor, in: RoundedRectangle(cornerRadius: 4))
      .opacity(isVisible ? 1 : 0)
      .animation(.easeInOut(duration: 0.2), value: isVisible)
  }
}

private struct ConstraintLine: View {
  let color: Color

  var body: some View {
    Rectangle()
      .fill(color)
  }
}

private struct WidthPreferenceKey: PreferenceKey {
  static let defaultValue: CGFloat = 0

  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}

private extension View {
  func readWidth(_ width: Binding<CGFloat>) -> some View {
    background(
      GeometryReader { proxy in
        Color.clear.preference(key: WidthPreferenceKey.self, value: proxy.size.width)
      },
    )
    .onPreferenceChange(WidthPreferenceKey.self) { value in
      if width.wrappedValue != value {
        width.wrappedValue = value
      }
    }
  }
}
