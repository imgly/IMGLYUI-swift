@_spi(Internal) import IMGLYCore
import IMGLYEngine
import SwiftUI

@_spi(Internal) public struct UploadMenu<Label: View>: View {
  @Environment(\.imglyAssetLibrarySources) private var sources
  @EnvironmentObject private var interactor: AnyAssetLibraryInteractor
  private let media: [MediaType]

  @State private var showImagePicker = false
  @State private var showCamera = false
  @State private var showFileImporter = false

  @ViewBuilder private let label: () -> Label

  @_spi(Internal) public init(media: [MediaType], @ViewBuilder label: @escaping () -> Label) {
    self.media = media
    self.label = label
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

  private func titleKey(for action: String) -> LocalizedStringKey {
    let suffix = if media.contains(.image), media.contains(.movie) {
      "Photo or Video"
    } else if media.contains(.image) {
      "Photo"
    } else {
      "Video"
    }
    return LocalizedStringKey(action + " " + suffix)
  }

  @_spi(Internal) public var body: some View {
    Menu {
      Button {
        showImagePicker.toggle()
      } label: {
        SwiftUI.Label(titleKey(for: "Choose"), systemImage: "photo.on.rectangle")
      }
      Button {
        showCamera.toggle()
      } label: {
        SwiftUI.Label(titleKey(for: "Take"), systemImage: "camera")
      }
      Button {
        showFileImporter.toggle()
      } label: {
        SwiftUI.Label(titleKey(for: "Select"), systemImage: "folder")
      }
    } label: {
      label()
    }
    .imgly.photoRoll(isPresented: $showImagePicker, media: media, maxSelectionCount: 1, onComplete: mediaCompletion)
    .imgly.camera(isPresented: $showCamera, media: media, onComplete: mediaCompletion)
    .imgly.assetFileUploader(isPresented: $showFileImporter, allowedContentTypes: media.map(\.contentType))
  }
}

struct UploadMenu_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
