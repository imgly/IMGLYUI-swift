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

  var mediaDescription: String {
    if media.contains(.image), media.contains(.movie) {
      "Photo or Video"
    } else if media.contains(.image) {
      "Photo"
    } else {
      "Video"
    }
  }

  @_spi(Internal) public var body: some View {
    Menu {
      Button {
        showImagePicker.toggle()
      } label: {
        SwiftUI.Label(LocalizedStringKey("Choose \(mediaDescription)"), systemImage: "photo.on.rectangle")
      }
      Button {
        showCamera.toggle()
      } label: {
        SwiftUI.Label(LocalizedStringKey("Take \(mediaDescription)"), systemImage: "camera")
      }
      Button {
        showFileImporter.toggle()
      } label: {
        SwiftUI.Label(LocalizedStringKey("Select \(mediaDescription)"), systemImage: "folder")
      }
    } label: {
      label()
    }
    .imgly.imagePicker(isPresented: $showImagePicker, media: media, onComplete: mediaCompletion)
    .imgly.camera(isPresented: $showCamera, media: media, onComplete: mediaCompletion)
    .imgly.assetFileUploader(isPresented: $showFileImporter, allowedContentTypes: media.map {
      switch $0 {
      case .image: .image
      case .movie: .movie
      }
    })
  }
}

struct UploadMenu_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
