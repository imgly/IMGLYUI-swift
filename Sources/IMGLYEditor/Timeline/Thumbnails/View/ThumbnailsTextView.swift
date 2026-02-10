import SwiftUI

/// Displays text content for text clips in the timeline.
/// Positioned after the label with truncation when space is limited.
/// When the clip is scrolled off-screen and text fits, the text "pins" to stay visible.
struct ThumbnailsTextView: View {
  private enum Metrics {
    static let horizontalPadding: CGFloat = 4
  }

  @ObservedObject var provider: ThumbnailsTextProvider
  let isZooming: Bool
  /// Measured width of the ClipLabelView including gap
  let labelWidth: CGFloat

  /// Measured intrinsic width of the text
  @State private var textWidth: CGFloat = 0

  var body: some View {
    GeometryReader { geometry in
      let layoutParams = Self.calculateLayout(
        geometry: geometry,
        labelWidth: labelWidth,
        textWidth: textWidth,
      )

      HStack(spacing: 0) {
        Text(provider.text)
          .font(.footnote)
          .lineLimit(1)
          .truncationMode(.tail)
          .foregroundStyle(.primary)
          .frame(maxWidth: layoutParams.textAvailableWidth, alignment: .leading)
          .background {
            // Hidden text to measure intrinsic width - only re-measures when text changes
            Text(provider.text)
              .font(.footnote)
              .lineLimit(1)
              .fixedSize()
              .hidden()
              .background(GeometryReader { textGeometry in
                Color.clear.preference(key: TextWidthPreferenceKey.self, value: textGeometry.size.width)
              })
          }
        Spacer(minLength: 0)
      }
      .frame(maxHeight: .infinity)
      .padding(.leading, layoutParams.leadingPadding)
      .padding(.trailing, Metrics.horizontalPadding)
    }
    .onPreferenceChange(TextWidthPreferenceKey.self) { width in
      // Only update if changed to avoid unnecessary renders
      if textWidth != width {
        textWidth = width
      }
    }
    .blur(radius: isZooming ? 10 : 0)
  }

  /// Layout parameters calculated from geometry
  private struct LayoutParams {
    let leadingPadding: CGFloat
    let textAvailableWidth: CGFloat
  }

  /// Pure function to calculate layout - enables compiler optimization
  @inline(__always)
  private static func calculateLayout(
    geometry: GeometryProxy,
    labelWidth: CGFloat,
    textWidth: CGFloat,
  ) -> LayoutParams {
    let availableWidth = geometry.size.width

    // Calculate frame relative to timeline coordinate space (more efficient than global)
    let frameInTimeline = geometry.frame(in: .named("timeline"))
    let clipLeftCutoff = frameInTimeline.minX < 0 ? -frameInTimeline.minX : 0

    // Ideal position: after the label
    let idealLeadingPadding = labelWidth + Metrics.horizontalPadding

    // Available width for text at ideal position
    let idealTextAvailableWidth = max(0, availableWidth - idealLeadingPadding - Metrics.horizontalPadding)

    // Check if text fits without truncation at the ideal position
    let textFits = textWidth > 0 && textWidth <= idealTextAvailableWidth

    // Calculate leading padding based on whether text fits
    // If text fits: use pinning behavior (push to stay visible, stop at right edge)
    // If text doesn't fit: use normal position with truncation
    let maxPadding = max(0, availableWidth - textWidth - Metrics.horizontalPadding)
    let pinnedPadding = idealLeadingPadding + clipLeftCutoff
    let leadingPadding = textFits ? min(pinnedPadding, maxPadding) : idealLeadingPadding

    // Calculate available width for text based on final padding
    let textAvailableWidth = max(0, availableWidth - leadingPadding - Metrics.horizontalPadding)

    return LayoutParams(leadingPadding: leadingPadding, textAvailableWidth: textAvailableWidth)
  }
}

/// Preference key to measure text width
private struct TextWidthPreferenceKey: PreferenceKey {
  static let defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}
