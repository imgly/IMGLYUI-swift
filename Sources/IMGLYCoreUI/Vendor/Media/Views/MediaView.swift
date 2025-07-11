#if os(iOS)
  import AVFoundation
  import CoreServices
  import Photos
  import SwiftUI
  import UniformTypeIdentifiers
  @_spi(Internal) import IMGLYCore

  @_spi(Internal) public typealias MediaCompletion = (Result<[(URL, MediaType)], Swift.Error>) -> Void

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

    var contentType: UTType {
      switch self {
      case .image: .image
      case .movie: .movie
      }
    }

    var identifier: String { contentType.identifier }
  }

  struct MediaView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme
    let source: UIImagePickerController.SourceType
    let media: [MediaType]
    let completion: MediaCompletion

    func makeUIViewController(context _: Context) -> CameraWrapper {
      CameraWrapper(isPresented: $isPresented,
                    source: source,
                    media: media,
                    colorScheme: colorScheme,
                    completion: completion)
    }

    func updateUIViewController(_ controller: CameraWrapper, context _: Context) {
      controller.isPresented = $isPresented
      controller.source = source
      controller.media = media
      controller.completion = completion
      controller.updateState()
      controller.colorScheme = colorScheme
    }
  }

  final class CameraWrapper: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate,
    UIAdaptivePresentationControllerDelegate {
    fileprivate var isPresented: Binding<Bool>
    fileprivate var source: UIImagePickerController.SourceType
    fileprivate var media: [MediaType]
    fileprivate var colorScheme: ColorScheme
    fileprivate var completion: MediaCompletion

    init(
      isPresented: Binding<Bool>,
      source: UIImagePickerController.SourceType,
      media: [MediaType],
      colorScheme: ColorScheme,
      completion: @escaping MediaCompletion
    ) {
      self.isPresented = isPresented
      self.source = source
      self.media = media
      self.colorScheme = colorScheme
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
      guard isAlreadyPresented != isPresented.wrappedValue, !isAlreadyPresented else { return }

      if source == .camera {
        let requiresMicrophone = media.contains { $0 == .movie }

        func handleMicrophonePermission() {
          guard requiresMicrophone else {
            presentImagePicker()
            return
          }

          switch AVCaptureDevice.authorizationStatus(for: .audio) {
          case .authorized:
            presentImagePicker()
          case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { micGranted in
              DispatchQueue.main.async {
                micGranted ? self.presentImagePicker() : self.presentMicrophonePermissionAlert()
              }
            }
          case .denied, .restricted:
            presentMicrophonePermissionAlert()
          @unknown default:
            presentMicrophonePermissionAlert()
          }
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
          handleMicrophonePermission()
        case .notDetermined:
          AVCaptureDevice.requestAccess(for: .video) { cameraGranted in
            DispatchQueue.main.async {
              cameraGranted ? handleMicrophonePermission() : self.presentCameraPermissionAlert()
            }
          }
        case .denied, .restricted:
          presentCameraPermissionAlert()
        @unknown default:
          presentCameraPermissionAlert()
        }
      } else {
        presentImagePicker()
      }
    }

    private func presentCameraPermissionAlert() {
      let alert = UIAlertController(
        title: String(localized: CamMicUsageDescriptionFromBundleHelper.shared.cameraAlertHeadline),
        message: String(localized: CamMicUsageDescriptionFromBundleHelper.shared.cameraUsageDescription),
        preferredStyle: .alert
      )
      alert.addAction(UIAlertAction(
        title: String(localized: .imgly.localized("ly_img_editor_dialog_permission_camera_button_dismiss")),
        style: .cancel
      ) { [weak self] _ in
        self?.isPresented.wrappedValue = false
      })

      alert.addAction(UIAlertAction(
        title: String(localized: .imgly.localized("ly_img_editor_dialog_permission_camera_button_confirm")),
        style: .default
      ) { _ in
        if let appSettings = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(appSettings) {
          UIApplication.shared.open(appSettings)
        }
      })
      present(alert, animated: true)
    }

    private func presentMicrophonePermissionAlert() {
      let alert = UIAlertController(
        title: String(localized: CamMicUsageDescriptionFromBundleHelper.shared.microphoneAlertHeadline),
        message: String(localized: CamMicUsageDescriptionFromBundleHelper.shared.microphoneUsageDescription),
        preferredStyle: .alert
      )
      alert.addAction(UIAlertAction(
        title: String(localized: .imgly.localized("ly_img_editor_dialog_permission_microphone_button_dismiss")),
        style: .cancel
      ) { [weak self] _ in
        self?.isPresented.wrappedValue = false
      })

      alert.addAction(UIAlertAction(
        title: String(localized: .imgly.localized("ly_img_editor_dialog_permission_microphone_button_confirm")),
        style: .default
      ) { _ in
        if let appSettings = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(appSettings) {
          UIApplication.shared.open(appSettings)
        }
      })
      present(alert, animated: true)
    }

    private func presentImagePicker() {
      let controller = UIImagePickerController()

      controller.sourceType = source
      controller.mediaTypes = media.map(\.identifier)
      if FeatureFlags.isEnabled(.transcodePickerImageImports) {
        controller.imageExportPreset = .compatible
      } else {
        controller.imageExportPreset = .current
      }
      if FeatureFlags.isEnabled(.transcodePickerVideoImports) {
        controller.videoExportPreset = AVAssetExportPresetHighestQuality
      } else {
        controller.videoExportPreset = AVAssetExportPresetPassthrough
      }
      controller.delegate = self
      controller.presentationController?.delegate = self
      controller.modalPresentationStyle = .automatic
      controller.overrideUserInterfaceStyle = (colorScheme == .dark) ? .dark : .light
      present(controller, animated: true, completion: nil)
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
            let url = try FileManager.default.getUniqueCacheURL()
              .appendingPathExtension(videoURL.pathExtension)

            try FileManager.default.moveOrCopyItem(at: videoURL, to: url)

            self?.complete(with: .success([(url, MediaType.movie)]), picker: picker)
          } catch {
            self?.complete(with: .failure(error), picker: picker)
          }
        }
        return
      }
      let imageURL = info[.imageURL] as? URL

      DispatchQueue.global().async { [weak self] in
        do {
          let url = try FileManager.default.getUniqueCacheURL()
            .appendingPathExtension(imageURL?.pathExtension ?? "jpg")

          if let imageURL {
            try FileManager.default.moveItem(at: imageURL, to: url)
          } else {
            let data = image.jpegData(compressionQuality: 1)
            try data?.write(to: url)
          }

          self?.complete(with: .success([(url, MediaType.image)]), picker: picker)
        } catch {
          self?.complete(with: .failure(error), picker: picker)
        }
      }
    }

    private nonisolated func complete(
      with result: Result<[(URL, MediaType)], Swift.Error>,
      picker: UIImagePickerController
    ) {
      DispatchQueue.main.async {
        self.isPresented.wrappedValue = false
        picker.presentingViewController?.dismiss(animated: true) {
          self.completion(result)
        }
      }
    }
  }
#endif
