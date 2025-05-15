@_spi(Internal) import IMGLYCore
import IMGLYEngine
import SwiftUI

/// A grid of assets with an upload button.
public struct UploadGrid: View {
  @Environment(\.imglyAssetLibrarySources) private var sources
  @EnvironmentObject private var interactor: AnyAssetLibraryInteractor
  private let media: [MediaType]

  /// Creates grid of assets with an upload button.
  /// - Parameter media: The allowed media type(s) to upload.
  public init(media: [MediaType]) {
    self.media = media
  }

  var mediaCompletion: MediaCompletion {
    { result in
      guard let source = sources.first else {
        return
      }
      Task {
        try await interactor.uploadAsset(to: source.id) {
          let (url, media) = try result.get()
          switch media {
          case .image: return .init(url: url, blockType: .graphic, blockKind: .key(.image), fillType: .image)
          case .movie: return .init(url: url, blockType: .graphic, blockKind: .key(.video), fillType: .video)
          }
        }
      }
    }
  }

  @State private var showImagePicker = false

  @ViewBuilder var firstAddButton: some View {
    UploadMenu(media: media) {
      ZStack {
        GridItemBackground()
        VStack(spacing: 6) {
          Image(systemName: "plus")
            .imageScale(.large)
          Text("Add")
            .font(.caption.weight(.medium))
        }
      }
    }
    .tint(.primary)
  }

  public var body: some View {
    ImageGrid { _ in
      // Don't show UploadMenu here as it behaves weird when changing the size of the sheet.
      UploadGridAddButton(showUploader: $showImagePicker)
    } first: {
      firstAddButton
    }
    .imgly.photoRoll(isPresented: $showImagePicker, media: media, onComplete: mediaCompletion)
  }
}

struct UploadGrid_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
