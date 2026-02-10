import CoreMedia
@_spi(Internal) import IMGLYCore
import SwiftUI

/// A label with automatic formatting for metadata in a `Clip`.
/// When `pinning` is enabled, the label stays visible when the clip is scrolled off-screen.
struct ClipLabelView: View {
  private enum Metrics {
    static let iconSize: CGFloat = 16
    static let horizontalPadding: CGFloat = 4
    static let verticalPadding: CGFloat = 2
    static let spacing: CGFloat = 2
    static let cornerRadius: CGFloat = 4
  }

  let duration: CMTime?
  let icon: Image?
  let title: String
  let isMuted: Bool
  let isSelectable: Bool
  let cornerRadius: CGFloat
  let isLooping: Bool
  /// When true, the label pins to stay visible when the clip scrolls off-screen
  var pinning: Bool = true
  /// Additional base padding added before pinning calculation (e.g., for trim overshoot)
  var basePadding: CGFloat = 0

  /// Whether this label has any visible content
  private var hasContent: Bool {
    duration != nil || isMuted || isLooping || !isSelectable || icon != nil || !title.isEmpty
  }

  var body: some View {
    if hasContent {
      if pinning {
        pinnedContent
      } else {
        labelContent
      }
    }
  }

  /// The label content wrapped in a GeometryReader for pinning behavior.
  /// Uses a single GeometryReader to minimize layout passes.
  private var pinnedContent: some View {
    // Single GeometryReader for all measurements
    GeometryReader { geometry in
      let availableWidth = geometry.size.width
      let frameInTimeline = geometry.frame(in: .named("timeline"))

      // Only calculate pinning offset when clip is actually cut off (performance optimization)
      let clipLeftCutoff = frameInTimeline.minX < 0 ? -frameInTimeline.minX : 0

      HStack {
        // Use overlay to measure label width without extra GeometryReader
        labelContent
          .overlay {
            GeometryReader { labelGeometry in
              // Calculate padding based on measured label width
              let labelWidth = labelGeometry.size.width
              let maxPadding = max(0, availableWidth - labelWidth - Metrics.horizontalPadding)
              let leadingPadding = min(basePadding + clipLeftCutoff, maxPadding)

              Color.clear
                .preference(key: PinningOffsetKey.self, value: leadingPadding)
            }
          }
        Spacer(minLength: 0)
      }
      .frame(maxHeight: .infinity)
      .modifier(PinningPaddingModifier())
    }
  }

  /// The actual label content - pure view with no measurement logic
  private var labelContent: some View {
    LabelContentView(
      duration: duration,
      icon: icon,
      title: title,
      isMuted: isMuted,
      isSelectable: isSelectable,
      isLooping: isLooping,
    )
  }
}

// MARK: - Extracted Label Content (Equatable for performance)

/// Pure view component for label content - extracted for better diffing
private struct LabelContentView: View, Equatable {
  private enum Metrics {
    static let iconSize: CGFloat = 16
    static let horizontalPadding: CGFloat = 4
    static let verticalPadding: CGFloat = 2
    static let spacing: CGFloat = 2
    static let cornerRadius: CGFloat = 4
  }

  let duration: CMTime?
  let icon: Image?
  let title: String
  let isMuted: Bool
  let isSelectable: Bool
  let isLooping: Bool

  nonisolated static func == (lhs: LabelContentView, rhs: LabelContentView) -> Bool {
    lhs.duration?.seconds == rhs.duration?.seconds &&
      lhs.title == rhs.title &&
      lhs.isMuted == rhs.isMuted &&
      lhs.isSelectable == rhs.isSelectable &&
      lhs.isLooping == rhs.isLooping
    // Note: icon comparison omitted as Image isn't Equatable, but icons rarely change
  }

  var body: some View {
    HStack(alignment: .center, spacing: Metrics.spacing) {
      if let duration {
        Text(duration.imgly.formattedDurationStringForClip())
          .fixedSize()
      }
      if isMuted {
        Image(systemName: "speaker.slash.fill")
          .frame(width: Metrics.iconSize, height: Metrics.iconSize)
      }
      if isLooping {
        Image(systemName: "infinity.circle")
          .frame(width: Metrics.iconSize, height: Metrics.iconSize)
      }
      if !isSelectable {
        Image(systemName: "lock")
          .frame(width: Metrics.iconSize, height: Metrics.iconSize)
      } else if let icon {
        icon
          .frame(width: Metrics.iconSize, height: Metrics.iconSize)
      }
      if !title.isEmpty {
        Text(title)
          .lineLimit(1)
      }
    }
    .font(.footnote)
    .monospacedDigit()
    .padding(.horizontal, Metrics.horizontalPadding)
    .padding(.vertical, Metrics.verticalPadding)
    .foregroundStyle(.primary)
    .background {
      RoundedRectangle(cornerRadius: Metrics.cornerRadius)
        .fill(.thinMaterial)
    }
    .padding(.leading, Metrics.horizontalPadding)
    .padding(.vertical, Metrics.verticalPadding)
    // Report width for external consumers (thumbnails positioning)
    .background {
      GeometryReader { geometry in
        Color.clear.preference(
          key: ClipLabelWidthKey.self,
          value: geometry.size.width,
        )
      }
    }
  }
}

// MARK: - Pinning Preference Key & Modifier

/// Internal preference key for passing pinning offset up the view hierarchy
private struct PinningOffsetKey: PreferenceKey {
  static let defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}

/// Modifier that applies the pinning padding from preference
private struct PinningPaddingModifier: ViewModifier {
  @State private var leadingPadding: CGFloat = 0

  func body(content: Content) -> some View {
    content
      .padding(.leading, leadingPadding)
      .onPreferenceChange(PinningOffsetKey.self) { newValue in
        // Only update if changed to avoid unnecessary renders
        if leadingPadding != newValue {
          leadingPadding = newValue
        }
      }
  }
}

// MARK: - Preview

struct ClipLabelView_Previews: PreviewProvider {
  static var previews: some View {
    VStack(alignment: .leading) {
      ClipLabelView(duration: CMTime(seconds: 20),
                    icon: Image(systemName: "video"),
                    title: "Video",
                    isMuted: true,
                    isSelectable: true,
                    cornerRadius: 8,
                    isLooping: true)
      ClipLabelView(duration: CMTime(seconds: 1.5),
                    icon: Image(systemName: "music.note"),
                    title: "Audio",
                    isMuted: false,
                    isSelectable: false,
                    cornerRadius: 8,
                    isLooping: false)
    }
  }
}
