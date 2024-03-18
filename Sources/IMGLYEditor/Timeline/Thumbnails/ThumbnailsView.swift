import SwiftUI

/// Displays a sequence of thumbnail preview images that the `ThumbnailsProvider` fetches.
struct ThumbnailsView: View {
  @ObservedObject var provider: ThumbnailsProvider

  let isZooming: Bool

  var body: some View {
    HStack(alignment: .top, spacing: 0) {
      ForEach(provider.images, id: \.self) { image in
        Image(uiImage: UIImage(cgImage: image ?? UIImage().cgImage!))
          .resizable()
          .frame(height: provider.thumbHeight)
          .frame(width: isZooming ? nil : provider.thumbHeight * provider.aspectRatio)
      }
    }
    .blur(radius: isZooming ? 10 : 0)
    .drawingGroup()
  }
}
