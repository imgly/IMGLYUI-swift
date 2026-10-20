import SwiftUI
import UIKit

/// Fits the upright captured images into the available area without cropping.
struct PhotoPreviewCanvas: View {
  let photo: Photo

  private var bounds: CGRect {
    photo.images.reduce(CGRect.null) { $0.union($1.rect) }
  }

  var body: some View {
    Group {
      if photo.images.count == 1, let image = photo.images.first {
        PhotoImageView(url: image.url)
      } else if !bounds.isEmpty {
        GeometryReader { geometry in
          let scale = min(geometry.size.width / bounds.width, geometry.size.height / bounds.height)
          ZStack(alignment: .topLeading) {
            ForEach(photo.images, id: \.url) { image in
              PhotoImageView(url: image.url)
                .frame(width: image.rect.width * scale, height: image.rect.height * scale)
                .offset(x: (image.rect.minX - bounds.minX) * scale,
                        y: (image.rect.minY - bounds.minY) * scale)
            }
          }
          .frame(width: bounds.width * scale, height: bounds.height * scale)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .cameraRotated()
    .background(Color.black)
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
          .scaledToFit()
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
