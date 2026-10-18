import SwiftUI
import UIKit

/// Renders captured JPEGs in the layout matching the live camera preview:
/// - Horizontal dual: HStack across the full safe area (no side bands).
/// - Vertical dual: VStack in a 9:16 area at the top, with a Spacer matching the live preview's
///   bottom letterbox.
/// - Standard (no layout): single photo, same 9:16-at-top as vertical.
struct PhotoPreviewCanvas: View {
  let photo: Photo
  let layoutMode: CameraLayoutMode?

  var body: some View {
    VStack(spacing: 0) {
      photosContainer
      Spacer(minLength: 0)
    }
    .background(Color.black)
  }

  @ViewBuilder private var photosContainer: some View {
    switch layoutMode {
    case .horizontal:
      HStack(spacing: 0) {
        ForEach(photo.images, id: \.url) { image in
          PhotoImageView(url: image.url)
        }
      }
      .aspectRatio(9 / 16, contentMode: .fit)
    case .vertical:
      VStack(spacing: 0) {
        ForEach(photo.images, id: \.url) { image in
          PhotoImageView(url: image.url)
        }
      }
      .aspectRatio(9 / 16, contentMode: .fit)
    case .none:
      if let image = photo.images.first {
        PhotoImageView(url: image.url)
          .aspectRatio(9 / 16, contentMode: .fit)
      }
    }
  }
}

private struct PhotoImageView: View {
  let url: URL

  @State private var image: UIImage?

  var body: some View {
    GeometryReader { geometry in
      if let image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .frame(width: geometry.size.width, height: geometry.size.height)
          .clipped()
      } else {
        Color.black
      }
    }
    .task(id: url) {
      image = await Self.loadImage(at: url)
    }
  }

  private nonisolated static func loadImage(at url: URL) async -> UIImage? {
    let data = try? Data(contentsOf: url)
    return data.flatMap(UIImage.init(data:))
  }
}
