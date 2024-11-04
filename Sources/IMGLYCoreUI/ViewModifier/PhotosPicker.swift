import PhotosUI
import SwiftUI
@_spi(Internal) import IMGLYCore

@_spi(Internal) public extension IMGLY where Wrapped: View {
  /// Presents the photos picker when `isPresented` is `true`
  /// - Parameters:
  ///   - isPresented: A binding to the boolean that will trigger the presentation
  ///   - media: An array that indicates the available media types
  ///   - onComplete: When an item has been selected, this will be called with the resulting URL to the file or an
  /// error
  @MainActor
  func photosPicker(isPresented: Binding<Bool>, media: [MediaType] = [.image],
                    onComplete: @escaping MediaCompletion) -> some View {
    wrapped.modifier(PhotosPicker(isPresented: isPresented, media: media, completion: onComplete))
  }
}

private extension View {
  @ViewBuilder
  func photosPickerEncodingOptions(_ visibility: Visibility) -> some View {
    if #available(iOS 17.0, *) {
      photosPickerAccessoryVisibility(visibility, edges: .bottom)
    } else {
      self
    }
  }
}

private struct PhotosPicker: ViewModifier {
  @Binding var isPresented: Bool
  let media: [MediaType]
  let completion: MediaCompletion

  @Features private var features
  @State private var selection: PhotosPickerItem?
  @State private var progress: Progress?

  func body(content: Content) -> some View {
    content
      .photosPicker(isPresented: $isPresented,
                    selection: $selection,
                    matching: .any(of: media.map(\.pickerFilter)),
                    preferredItemEncoding: features.isEnabled(.transcodePickerImports) ? .compatible : .current)
      .photosPickerEncodingOptions(features.isEnabled(.photosPickerEncodingOptions) ? .visible : .hidden)
      .onChange(of: selection) { newSelection in
        guard let newSelection else {
          return
        }
        defer {
          selection = nil
        }
        guard let preferredContentType = newSelection.supportedContentTypes.first else {
          completion(.failure(Error(errorDescription: "Unknown supported content types.")))
          return
        }

        func loadTransferable(type: (some MediaItem).Type) -> Progress? {
          guard preferredContentType.conforms(to: type.mediaType.contentType) else {
            return nil
          }
          return newSelection.loadTransferable(type: type, completionHandler: loadTransferableCompletion)
        }

        if let progress = loadTransferable(type: MovieMediaItem.self) {
          self.progress = progress
        } else if let progress = loadTransferable(type: ImageMediaItem.self) {
          self.progress = progress
        } else {
          completion(.failure(Error(errorDescription: "Unsupported preferred content type.")))
        }
      }
      .overlay {
        if let progress, !progress.isFinished, !progress.isCancelled {
          VStack(spacing: 12) {
            ProgressView()
            Text("Importing asset...")
              .font(.footnote)
          }
          .padding(24)
          .background {
            RoundedRectangle(cornerRadius: 8)
              .fill(.regularMaterial)
          }
        }
      }
  }

  private func loadTransferableCompletion<Item: MediaItem>(result: Result<Item?, Swift.Error>) {
    // Dispatch to main is done in most Apple PhotosPicker examples if not the async `loadTransferable` variant is used.
    DispatchQueue.main.async {
      switch result {
      case let .success(selection):
        guard let selection else {
          completion(.failure(Error(errorDescription: "Could not load transferable.")))
          return
        }
        completion(.success((selection.url, Item.mediaType)))
      case let .failure(error):
        completion(.failure(error))
      }
      progress = nil
    }
  }
}

private extension MediaType {
  var pickerFilter: PHPickerFilter {
    switch self {
    case .image: .images
    case .movie: .videos
    }
  }
}

private extension URL {
  func moveOrCopyToUniqueCacheURL() throws -> URL {
    let manager = FileManager.default
    let url = try manager.getUniqueCacheURL().appendingPathExtension(pathExtension)
    try manager.moveOrCopyItem(at: self, to: url)
    return url
  }

  /// Transcode to most compatible format
  func transcode(mediaType: MediaType) async throws -> URL {
    switch mediaType {
    case .image: try await transcodeImage()
    case .movie: try await transcodeMovie()
    }
  }

  /// Transcode to most compatible image format
  private func transcodeImage() async throws -> URL {
    let (imageData, _) = try await URLSession.shared.get(self)
    guard let image = UIImage(data: imageData) else {
      throw Error(errorDescription: "Could not load image for transcoding.")
    }
    guard let jpegData = image.jpegData(compressionQuality: 1) else {
      throw Error(errorDescription: "Could not save image for transcoding.")
    }
    return try jpegData.writeToUniqueCacheURL(for: .jpeg)
  }

  /// Transcode to most compatible movie format
  private func transcodeMovie() async throws -> URL {
    guard let session = AVAssetExportSession(asset: AVAsset(url: self),
                                             presetName: AVAssetExportPresetHighestQuality) else {
      throw Error(errorDescription: "Could not create asset export session for transcoding.")
    }
    let outputURL = try FileManager.default.getUniqueCacheURL().appendingPathExtension(for: .quickTimeMovie)
    session.outputURL = outputURL
    session.outputFileType = .mov
    await session.export()
    if let error = session.error {
      throw error
    }
    return outputURL
  }
}

private protocol MediaItem: Transferable {
  init(url: URL)
  var url: URL { get }
  static var mediaType: MediaType { get }
}

private struct MediaItemTransferRepresentation<Item: MediaItem>: TransferRepresentation {
  let contentType: UTType
  let transcode: Bool

  var body: some TransferRepresentation {
    FileRepresentation(contentType: contentType) { item in
      SentTransferredFile(item.url)
    } importing: { received in
      if transcode, await FeatureFlags.isEnabled(.transcodePickerImports) {
        // Force transcode because if photos picker encoding options introduced with iOS 17 were ever changed per app
        // `preferredItemEncoding` is ignored. Erasing the simulator helps, deleting the app, and/or restarting the
        // device does not!
        try await Item(url: received.file.transcode(mediaType: Item.mediaType))
      } else {
        try Item(url: received.file.moveOrCopyToUniqueCacheURL())
      }
    }
  }
}

private struct MovieMediaItem: MediaItem {
  let url: URL
  static let mediaType: MediaType = .movie

  static var transferRepresentation: some TransferRepresentation {
    MediaItemTransferRepresentation(contentType: mediaType.contentType, transcode: true)
  }
}

private struct ImageMediaItem: MediaItem {
  let url: URL
  static let mediaType: MediaType = .image

  static var transferRepresentation: some TransferRepresentation {
    MediaItemTransferRepresentation(contentType: .jpeg, transcode: false)
    MediaItemTransferRepresentation(contentType: .png, transcode: false)
    MediaItemTransferRepresentation(contentType: mediaType.contentType, transcode: true)
  }
}
