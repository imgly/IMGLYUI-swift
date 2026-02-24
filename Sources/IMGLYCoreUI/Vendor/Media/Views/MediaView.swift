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

    // Keep a strong reference to self to prevent deallocation during navigation
    private var strongSelfReference: CameraWrapper?

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

      Task {
        if source == .camera {
          guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }

          let requiresMicrophone = media.contains { $0 == .movie }

          let isCameraGranted = await ensurePermission(.camera)
          guard isCameraGranted else { return presentCameraPermissionAlert() }

          if requiresMicrophone {
            let isMicrophoneGranted = await ensurePermission(.microphone)
            guard isMicrophoneGranted else { return presentMicrophonePermissionAlert() }

            do {
              AVAudioSession.push()
              try AVAudioSession.prepareForRecording()
            } catch {
              print("Couldn't prepare session for recording")
            }
          }

          presentImagePicker()
        } else {
          presentImagePicker()
        }
      }
    }

    private func popAudioSessionIfNeeded() {
      let requiresMicrophone = media.contains { $0 == .movie }
      guard source == .camera, requiresMicrophone else {
        return
      }
      do {
        try AVAudioSession.pop()
      } catch {
        print("Couldn't return session to previous mode \(error)")
      }
    }

    // MARK: - Permissions

    private enum MediaPermission {
      case camera, microphone

      var type: AVMediaType { self == .camera ? .video : .audio }
    }

    private func ensurePermission(_ permission: MediaPermission) async -> Bool {
      let type = permission.type
      switch AVCaptureDevice.authorizationStatus(for: type) {
      case .authorized:
        return true
      case .notDetermined:
        return await AVCaptureDevice.imgly.requestAccess(for: type)
      case .denied, .restricted:
        return false
      @unknown default:
        return false
      }
    }

    // MARK: - UI

    private func presentCameraPermissionAlert() {
      let alert = UIAlertController(
        title: String(localized: CamMicUsageDescriptionFromBundleHelper.cameraAlertHeadline),
        message: String(localized: CamMicUsageDescriptionFromBundleHelper.cameraUsageDescription),
        preferredStyle: .alert,
      )
      alert.addAction(UIAlertAction(
        title: String(localized: .imgly.localized("ly_img_editor_dialog_permission_camera_button_dismiss")),
        style: .cancel,
      ) { [weak self] _ in
        self?.isPresented.wrappedValue = false
      })

      alert.addAction(UIAlertAction(
        title: String(localized: .imgly.localized("ly_img_editor_dialog_permission_camera_button_confirm")),
        style: .default,
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
        title: String(localized: CamMicUsageDescriptionFromBundleHelper.microphoneAlertHeadline),
        message: String(localized: CamMicUsageDescriptionFromBundleHelper.microphoneUsageDescription),
        preferredStyle: .alert,
      )
      alert.addAction(UIAlertAction(
        title: String(localized: .imgly.localized("ly_img_editor_dialog_permission_microphone_button_dismiss")),
        style: .cancel,
      ) { [weak self] _ in
        self?.isPresented.wrappedValue = false
      })

      alert.addAction(UIAlertAction(
        title: String(localized: .imgly.localized("ly_img_editor_dialog_permission_microphone_button_confirm")),
        style: .default,
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
      controller.imageExportPreset = FeatureFlags.isEnabled(.transcodePickerImageImports) ? .compatible : .current
      controller.videoExportPreset = FeatureFlags
        .isEnabled(.transcodePickerVideoImports) ? AVAssetExportPresetHighestQuality : AVAssetExportPresetPassthrough
      controller.delegate = self
      controller.presentationController?.delegate = self
      controller.modalPresentationStyle = .automatic
      controller.overrideUserInterfaceStyle = (colorScheme == .dark) ? .dark : .light

      strongSelfReference = self
      present(controller, animated: true)
    }

    // MARK: - Delegates

    func presentationControllerDidDismiss(_: UIPresentationController) {
      strongSelfReference = nil
      isPresented.wrappedValue = false
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      popAudioSessionIfNeeded()

      strongSelfReference = nil
      isPresented.wrappedValue = false
      picker.presentingViewController?.dismiss(animated: true)
    }

    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any],
    ) {
      popAudioSessionIfNeeded()

      guard let image = info[.originalImage] as? UIImage else {
        guard let videoURL = info[.mediaURL] as? URL else {
          complete(with: .failure(MediaError.imageNotAvailable), picker: picker)
          return
        }
        // swiftlint:disable:next task_detached
        Task.detached(priority: .userInitiated) { [weak self] in
          do {
            let url = try FileManager.default.getUniqueCacheURL()
              .appendingPathExtension(videoURL.pathExtension)

            try FileManager.default.moveOrCopyItem(at: videoURL, to: url)

            await self?.complete(with: .success([(url, MediaType.movie)]), picker: picker)
          } catch {
            await self?.complete(with: .failure(error), picker: picker)
          }
        }
        return
      }

      let imageURL = info[.imageURL] as? URL
      // swiftlint:disable:next task_detached
      Task.detached(priority: .userInitiated) { [weak self] in
        do {
          let url = try FileManager.default.getUniqueCacheURL()
            .appendingPathExtension(imageURL?.pathExtension ?? "jpg")

          if let imageURL {
            try FileManager.default.moveItem(at: imageURL, to: url)
          } else if let data = image.jpegData(compressionQuality: 1) {
            try data.write(to: url)
          } else {
            throw MediaError.imageNotAvailable
          }

          await self?.complete(with: .success([(url, MediaType.image)]), picker: picker)
        } catch {
          await self?.complete(with: .failure(error), picker: picker)
        }
      }
    }

    // MARK: - Completion

    private func complete(
      with result: Result<[(URL, MediaType)], Swift.Error>,
      picker: UIImagePickerController,
    ) {
      strongSelfReference = nil
      isPresented.wrappedValue = false
      picker.presentingViewController?.dismiss(animated: true) {
        self.completion(result)
      }
    }
  }
#endif
