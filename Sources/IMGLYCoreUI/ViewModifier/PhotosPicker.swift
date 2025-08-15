import Combine
import PhotosUI
import SwiftUI
@_spi(Internal) import IMGLYCore

@_spi(Internal) public extension IMGLY where Wrapped: View {
  /// Presents the photos picker when `isPresented` is `true`
  /// - Parameters:
  ///   - isPresented: A binding to the boolean that will trigger the presentation
  ///   - media: An array that indicates the available media types
  ///   - maxSelectionCount: An integer that determines the max number of selections
  ///   - onComplete: When an item has been selected, this will be called with the resulting URL to the file or an
  /// error
  @MainActor
  func photosPicker(isPresented: Binding<Bool>, media: [MediaType] = [.image],
                    maxSelectionCount: Int?, onComplete: @escaping MediaCompletion) -> some View {
    wrapped.modifier(PhotosPicker(isPresented: isPresented, media: media,
                                  maxSelectionCount: maxSelectionCount, completion: onComplete))
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
  let maxSelectionCount: Int?
  let completion: MediaCompletion

  @Features private var features

  @State private var selections = [PhotosPickerItem]()
  @State private var shouldShowImportingOverlay = false
  @State private var importingProgress = [PhotosPickerItem: Double]()
  @State private var cancellables = Set<AnyCancellable>()

  private var currentProgress: Double {
    guard !importingProgress.isEmpty else { return 0 }

    return importingProgress.map(\.value).reduce(0, +) / Double(importingProgress.count)
  }

  private var importingText: Text? {
    guard !importingProgress.isEmpty else { return nil }

    return Text("Importing ^[\(importingProgress.count) asset](inflect: true)")
  }

  func body(content: Content) -> some View {
    content
      .photosPicker(isPresented: $isPresented,
                    selection: $selections,
                    maxSelectionCount: maxSelectionCount,
                    selectionBehavior: .ordered,
                    matching: .any(of: media.map(\.pickerFilter)),
                    preferredItemEncoding: .current)
      .onChange(of: selections) { newSelections in
        guard !newSelections.isEmpty else { return }

        selections = []
        handleSelections(with: newSelections)
      }
      .photosPickerEncodingOptions(features.isEnabled(.photosPickerEncodingOptions) ? .visible : .hidden)
      .overlay {
        if shouldShowImportingOverlay, let importingText {
          VStack(spacing: 12) {
            ProgressView(value: currentProgress)

            importingText
              .font(.footnote)
          }
          .padding(24)
          .background {
            RoundedRectangle(cornerRadius: 8)
              .fill(.regularMaterial)
          }
          .padding(32)
        }
      }
  }

  private func handleSelections(with selections: [PhotosPickerItem]) {
    Task { @MainActor in
      let overlayTask = Task {
        // Delay showing the overlay to avoid flashing it for quick imports
        try await Task.sleep(for: .seconds(1))

        guard !Task.isCancelled else { return }

        shouldShowImportingOverlay = true
      }

      do {
        let results = try await withThrowingTaskGroup(of: (Int, (URL, MediaType)).self) { group in
          for (index, selection) in selections.enumerated() {
            group.addTask {
              try await (index, loadTransferable(with: selection))
            }
          }
          var unorderedResults = [(Int, (URL, MediaType))]()
          for try await result in group {
            unorderedResults.append(result)
          }
          return unorderedResults.sorted { $0.0 < $1.0 }.map(\.1)
        }
        completion(.success(results))
      } catch {
        completion(.failure(error))
      }

      overlayTask.cancel()
      importingProgress = [:]
      shouldShowImportingOverlay = false
    }
  }

  private func loadTransferable(with selection: PhotosPickerItem) async throws -> (URL, MediaType) {
    guard let preferredContentType = selection.supportedContentTypes.first else {
      throw Error(errorDescription: "Unknown supported content types.")
    }

    guard let mediaItemType = getMediaItemType(for: preferredContentType) else {
      throw Error(errorDescription: "Unsupported preferred content type.")
    }

    guard let url = try await loadMediaItem(selection, with: mediaItemType) else {
      throw Error(errorDescription: "Could not load transferable.")
    }

    return (url, mediaItemType.mediaType)
  }

  private func getMediaItemType(for preferredContentType: UTType) -> (any MediaItem.Type)? {
    if preferredContentType.conforms(to: MovieMediaItem.mediaType.contentType),
       media.contains(MovieMediaItem.mediaType) {
      MovieMediaItem.self
    } else if preferredContentType.conforms(to: ImageMediaItem.mediaType.contentType),
              media.contains(ImageMediaItem.mediaType) {
      ImageMediaItem.self
    } else {
      nil
    }
  }

  private func loadMediaItem(_ selection: PhotosPickerItem, with type: (some MediaItem).Type) async throws -> URL? {
    try await withCheckedThrowingContinuation { continuation in
      selection.loadTransferable(type: type) { result in
        switch result {
        case let .success(item):
          continuation.resume(returning: item?.url)
        case let .failure(error):
          continuation.resume(throwing: error)
        }
      }
      .publisher(for: \.fractionCompleted)
      .sink { fractionCompleted in
        importingProgress[selection] = fractionCompleted
      }
      .store(in: &cancellables)
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
      let transcodePickerImports = switch Item.mediaType {
      case .image: await FeatureFlags.isEnabled(.transcodePickerImageImports)
      case .movie: await FeatureFlags.isEnabled(.transcodePickerVideoImports)
      }
      return if transcode, transcodePickerImports {
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
