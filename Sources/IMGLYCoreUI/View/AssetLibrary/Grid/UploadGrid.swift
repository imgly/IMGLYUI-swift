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
        for (url, media) in try result.get() {
          _ = try await interactor.uploadAsset(to: source.id) {
            switch media {
            case .image: .init(url: url, blockType: .graphic, blockKind: .key(.image), fillType: .image)
            case .movie: .init(url: url, blockType: .graphic, blockKind: .key(.video), fillType: .video)
            }
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
          Text(.imgly.localized("ly_img_editor_asset_library_button_add"))
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
    .imgly.photoRoll(isPresented: $showImagePicker, media: media, maxSelectionCount: 1, onComplete: mediaCompletion)
  }
}

struct UploadGrid_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
