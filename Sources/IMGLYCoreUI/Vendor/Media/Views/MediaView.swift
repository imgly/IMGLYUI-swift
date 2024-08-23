#if os(iOS)
  import CoreServices
  import Photos
  import SwiftUI
  import UniformTypeIdentifiers

  @_spi(Internal) public typealias MediaCompletion = (Result<(URL, MediaType), Error>) -> Void

  @_spi(Internal) public enum MediaError: LocalizedError {
    case imageNotAvailable
    case urlMissing

    @_spi(Internal) public var errorDescription: String? {
      switch self {
      case .imageNotAvailable:
        NSLocalizedString("The original image was not available", comment: "")
      case .urlMissing:
        NSLocalizedString("The URL was missing", comment: "")
      }
    }
  }

  public enum MediaType: Sendable {
    case image
    case movie

    var identifier: String {
      switch self {
      case .image: UTType.image.identifier
      case .movie: UTType.movie.identifier
      }
    }
  }

  struct MediaView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let source: UIImagePickerController.SourceType
    let media: [MediaType]
    let completion: MediaCompletion

    func makeUIViewController(context _: Context) -> CameraWrapper {
      CameraWrapper(isPresented: $isPresented, source: source, media: media, completion: completion)
    }

    func updateUIViewController(_ controller: CameraWrapper, context _: Context) {
      controller.isPresented = $isPresented
      controller.source = source
      controller.media = media
      controller.completion = completion
      controller.updateState()
    }
  }

  final class CameraWrapper: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate,
    UIAdaptivePresentationControllerDelegate {
    fileprivate var isPresented: Binding<Bool>
    fileprivate var source: UIImagePickerController.SourceType
    fileprivate var media: [MediaType]
    fileprivate var completion: MediaCompletion

    init(
      isPresented: Binding<Bool>,
      source: UIImagePickerController.SourceType,
      media: [MediaType],
      completion: @escaping MediaCompletion
    ) {
      self.isPresented = isPresented
      self.source = source
      self.media = media
      self.completion = completion

      super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func didMove(toParent parent: UIViewController?) {
      super.didMove(toParent: parent)
      updateState()
    }

    func updateState() {
      let isAlreadyPresented = presentedViewController != nil

      if isAlreadyPresented != isPresented.wrappedValue {
        if !isAlreadyPresented {
          let controller = UIImagePickerController()

          controller.sourceType = source
          controller.mediaTypes = media.map(\.identifier)
          controller.imageExportPreset = .compatible
          controller.videoExportPreset = AVAssetExportPresetPassthrough

          controller.delegate = self
          controller.presentationController?.delegate = self
          controller.modalPresentationStyle = .automatic
          present(controller, animated: true, completion: nil)
        }
      }
    }

    func presentationControllerDidDismiss(_: UIPresentationController) {
      isPresented.wrappedValue = false
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      isPresented.wrappedValue = false
      picker.presentingViewController?.dismiss(animated: true)
    }

    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      guard let image = info[.originalImage] as? UIImage else {
        guard let videoURL = info[.mediaURL] as? URL else {
          complete(with: .failure(MediaError.imageNotAvailable), picker: picker)
          return
        }

        DispatchQueue.global().async { [weak self] in
          do {
            let url = try FileManager.default.url(
              for: .cachesDirectory,
              in: .userDomainMask,
              appropriateFor: nil,
              create: false
            )
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(videoURL.pathExtension)

            do {
              try FileManager.default.moveItem(at: videoURL, to: url)
            } catch {
              try FileManager.default.copyItem(at: videoURL, to: url)
            }
            self?.complete(with: .success((url, MediaType.movie)), picker: picker)
          } catch {
            self?.complete(with: .failure(error), picker: picker)
          }
        }
        return
      }
      let imageURL = info[.imageURL] as? URL

      DispatchQueue.global().async { [weak self] in
        do {
          let url = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
          )
          .appendingPathComponent(UUID().uuidString)
          .appendingPathExtension(imageURL?.pathExtension ?? "jpg")

          if let imageURL {
            try FileManager.default.moveItem(at: imageURL, to: url)
          } else {
            let data = image.jpegData(compressionQuality: 1)
            try data?.write(to: url)
          }

          self?.complete(with: .success((url, MediaType.image)), picker: picker)
        } catch {
          self?.complete(with: .failure(error), picker: picker)
        }
      }
    }

    private nonisolated func complete(with result: Result<(URL, MediaType), Error>, picker: UIImagePickerController) {
      DispatchQueue.main.async {
        self.isPresented.wrappedValue = false
        picker.presentingViewController?.dismiss(animated: true) {
          self.completion(result)
        }
      }
    }
  }
#endif
