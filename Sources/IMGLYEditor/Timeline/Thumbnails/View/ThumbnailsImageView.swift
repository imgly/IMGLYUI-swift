import SwiftUI

/// Displays a sequence of thumbnail preview images that the `ThumbnailsProvider` fetches.
struct ThumbnailsImageView: View {
  private enum Metrics {
    static let horizontalMargin: CGFloat = 2
  }

  @ObservedObject var provider: ThumbnailsImageProvider
  let isZooming: Bool
  /// Measured width of the ClipLabelView
  let labelWidth: CGFloat
  /// Trim offset applied when using the left trim handler (negative value means trimmed from start)
  let trimOffset: CGFloat

  /// Determines if this clip type shows a single static thumbnail
  private var isStillContent: Bool {
    switch provider.clipType {
    case .image, .sticker, .shape:
      true
    default:
      false
    }
  }

  var body: some View {
    Group {
      if isStillContent {
        // Still content (images, stickers, shapes) shows a single thumbnail
        singleThumbnailView
      } else {
        // Video and other types show multiple thumbnails
        multiThumbnailView
      }
    }
    .blur(radius: isZooming ? 10 : 0)
  }

  /// View for still content (images, stickers, shapes) - single thumbnail
  /// Thumbnail is positioned after the label when there's space.
  /// As clip narrows, thumbnail smoothly slides under the label.
  /// When the clip is scrolled off-screen, the thumbnail "pins" to the visible left edge.
  private var singleThumbnailView: some View {
    // Pre-calculate thumbnail width outside GeometryReader (constant value)
    let thumbnailWidth = provider.thumbHeight * provider.aspectRatio
    // Pre-calculate trim compensation (only changes when trimOffset changes)
    let trimCompensation = -trimOffset

    return GeometryReader { geometry in
      // Calculate pinning only when needed
      let leadingPadding = Self.calculateLeadingPadding(
        geometry: geometry,
        thumbnailWidth: thumbnailWidth,
        labelWidth: labelWidth,
        trimCompensation: trimCompensation,
      )

      HStack(alignment: .center, spacing: 0) {
        if let image = provider.images.first ?? nil {
          Image(uiImage: UIImage(cgImage: image))
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: thumbnailWidth, height: provider.thumbHeight)
            .clipped()
        }
        Spacer(minLength: 0)
      }
      .frame(height: provider.thumbHeight)
      .padding(.leading, leadingPadding)
    }
  }

  /// Pure function to calculate leading padding - enables better optimization by compiler
  @inline(__always)
  private static func calculateLeadingPadding(
    geometry: GeometryProxy,
    thumbnailWidth: CGFloat,
    labelWidth: CGFloat,
    trimCompensation: CGFloat,
  ) -> CGFloat {
    let availableWidth = geometry.size.width

    // Calculate frame relative to timeline coordinate space (more efficient than global)
    let frameInTimeline = geometry.frame(in: .named("timeline"))
    let clipLeftCutoff = frameInTimeline.minX < 0 ? -frameInTimeline.minX : 0

    // Maximum padding to keep thumbnail within clip bounds (right edge)
    let maxPadding = max(0, availableWidth - thumbnailWidth - Metrics.horizontalMargin + trimCompensation)

    // Ideal position: after the label, adjusted for trim
    let idealPadding = labelWidth + Metrics.horizontalMargin + trimCompensation

    // Pinned position: shift by cutoff amount when scrolled off-screen
    let pinnedPadding = idealPadding + clipLeftCutoff

    // Final padding: use pinned position, clamped to stay within clip bounds
    return min(pinnedPadding, maxPadding)
  }

  /// View for video and dynamic content - multiple thumbnails
  private var multiThumbnailView: some View {
    HStack(alignment: .top, spacing: 0) {
      ForEach(provider.images, id: \.self) { image in
        if let image {
          Image(uiImage: UIImage(cgImage: image))
            .resizable()
            .frame(width: isZooming ? nil : provider.thumbWidth,
                   height: provider.thumbHeight)
        }
      }
    }
  }
}
