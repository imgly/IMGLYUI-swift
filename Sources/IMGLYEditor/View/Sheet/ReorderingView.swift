import SwiftUI

/// Wraps the thumbnails that reorder the `Clip`s in a `Track`.
struct ReorderingView: View {
  @EnvironmentObject var interactor: AnyTimelineInteractor

  @ObservedObject var track: Track
  @ScaledMetric var thumbnailHeight = 80
  @ScaledMetric var thumbnailSpacing = 8

  @State var draggedClip: Clip?

  var body: some View {
    GeometryReader { geometry in
      ScrollView(.horizontal) {
        HStack(spacing: thumbnailSpacing) {
          let clips = track.clips
          ForEach(Array(zip(clips, clips.indices)), id: \.0) { clip, index in
            if let thumbnailProvider = try? interactor.timelineProperties.thumbnailsManager
              .getProvider(clip: clip) as? ThumbnailsImageProvider {
              ReorderingThumbnailView(index: index,
                                      clip: clip,
                                      clips: $track.clips,
                                      draggedClip: $draggedClip,
                                      thumbnailHeight: thumbnailHeight,
                                      thumbnailSpacing: thumbnailSpacing,
                                      thumbnailsProvider: thumbnailProvider)
                .zIndex(clip == draggedClip ? 1 : 0)
            }
          }
        }
        .padding(.horizontal, 32)
        .frame(minWidth: geometry.size.width)
        .frame(minHeight: geometry.size.height - 88)
      }
    }
    .scrollIndicators(.never)
    .background {
      if track.clips.count > 0 {
        Text("Press and hold to Reorder")
          .font(.footnote)
          .foregroundColor(.secondary)
          .offset(y: thumbnailHeight)
      } else {
        Text("No clips in background track.")
          .font(.footnote)
          .foregroundColor(.secondary)
      }
    }
  }
}
