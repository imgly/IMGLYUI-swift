import AVFoundation
import Combine
import CoreMedia
import Foundation
import SwiftUI
@_spi(Internal) import IMGLYCoreUI
@_spi(Internal) import IMGLYCore

/// Internal type for unifying handling of old and new school `onDismiss` callbacks.
enum CameraOnDismissCallback {
  case legacy((Result<[Recording], CameraError>) -> Void)
  case modern((Result<CameraResult, CameraError>) -> Void)

  func emit(_ result: Result<CameraResult, CameraError>) {
    switch (self, result) {
    case let (.modern(callback), result):
      callback(result)

    case let (.legacy(callback), .failure(error)):
      callback(.failure(error))

    case let (.legacy(callback), .success(.reaction(video, recordings))):
      callback(.success([video] + recordings))

    case let (.legacy(callback), .success(.capture(captures))):
      // The legacy callback only carries `[Recording]`, so photos are dropped. The deprecated
      // initializer forces `captureType: .video` to prevent that silently — see `Camera.init`.
      callback(.success(captures.videos))
    }
  }
}

/// Provides camera state and functionality to the `Camera`.
/// - Manages the `CaptureService`.
/// - Manages the `CameraCanvasInteractor` that provides the `CameraCanvasView` and interfaces with the `IMGLYEngine`.
@MainActor
final class CameraModel: ObservableObject {
  let configuration: CameraConfiguration
  let recordingsManager: RecordingsManager
  let isMultiCamSupported = AVCaptureMultiCamSession.isMultiCamSupported

  private var onDismiss: CameraOnDismissCallback

  private(set) var interactor: CameraCanvasInteractor?
  private var cameraStreamTask: Task<Void, Swift.Error>?
  private var isInitializingStream = false

  private var didEnterBackgroundNotificationPublisher: AnyCancellable?
  private var didBecomeActiveNotificationPublisher: AnyCancellable?
  private var willResignActiveNotificationPublisher: AnyCancellable?
  private var captureSessionRuntimeErrorNotificationPublisher: AnyCancellable?
  private var captureSessionWasInterruptedNotificationPublisher: AnyCancellable?
  private var captureSessionInterruptionEndedNotificationPublisher: AnyCancellable?
  private var hasCamera = false

  private let captureService: CaptureService
  private let settings: EngineSettings

  // MARK: - State

  enum CameraState: Equatable {
    case preparing
    case ready
    case countingDown
    case recording
    case capturingPhoto
    case previewingPhoto(Photo)
    case error(CameraCaptureError)
  }

  @Published private(set) var state = CameraState.preparing
  @Published var cameraMode: CameraMode = .standard {
    didSet {
      cameraModeUpdated(cameraMode, oldValue)
    }
  }

  @Published private(set) var reactionVideoDuration: CMTime?
  @Published private(set) var hasVideoPermissions = false
  @Published private(set) var hasAudioPermissions = false
  @Published private(set) var isLoadingAsset: Bool = false
  @Published var alertState: AlertState?

  /// Drives shutter routing while `captureType == .mixed`. Ignored for `.photo` / `.video`.
  @Published var activeMixedSubMode: ActiveMixedSubMode = .photo {
    didSet {
      captureService.setFlash(mode: torchMode)
    }
  }

  /// The torch state to apply to the device. Photo capture flashes via `AVCapturePhotoSettings`
  /// at shutter time, so the persistent torch only runs in video mode.
  private var torchMode: FlashMode {
    isVideoModeActive ? flashMode : .off
  }

  /// True when a tap would start a video recording.
  var isVideoModeActive: Bool {
    switch configuration.captureType {
    case .video: true
    case .photo: false
    case .mixed: activeMixedSubMode == .video
    }
  }

  var hasRecordings: Bool {
    !recordingsManager.captures.isEmpty
  }

  var isRecording: Bool {
    captureService.isRecording
  }

  var shouldShowCamera: Bool {
    // If we're not in reaction mode, always show camera
    guard case .reaction = cameraMode else {
      return true
    }

    // If we're in reaction mode, only show camera if the reaction video finished loading
    // reactionVideoDuration will be nil if loading failed or if there's no video
    return !isLoadingAsset && reactionVideoDuration != nil
  }

  private var cancellables: Set<AnyCancellable> = []

  // Prevents double cleanup, and lets views hide chrome while the modal animates away.
  @Published private(set) var isDismissalInProgress = false

  // MARK: - Lifecycle

  init(
    _ settings: EngineSettings,
    config: CameraConfiguration = .init(),
    mode: CameraMode = .standard,
    onDismiss: CameraOnDismissCallback
  ) {
    self.onDismiss = onDismiss
    self.settings = settings
    cameraMode = mode
    configuration = config
    captureService = CaptureService(captureType: config.captureType)
    recordingsManager = RecordingsManager(
      maxTotalDuration: configuration.maxTotalDuration,
      allowExceedingMaxDuration: configuration.allowExceedingMaxDuration,
    )
    configureNotificationHandlers()
    updateCameraCapabilities()
    configureObservations()

    captureService.delegate = self

    if mode.isReaction {
      flipCamera()
    }
  }

  private func configureObservations() {
    // Observe the reaction video duration and update the recording manager's max duration accordingly.
    $reactionVideoDuration
      .replaceNil(with: configuration.maxTotalDuration)
      .assignNoRetain(to: \.maxTotalDuration, on: recordingsManager)
      .store(in: &cancellables)
  }

  private func cleanUp(callback: (@MainActor () -> Void)? = nil) {
    stopRecording()
    stopStreaming(callback: callback)
    interactor?.destroyEngine()
  }

  // MARK: - Callback

  func done() {
    guard !isDismissalInProgress else { return }
    isDismissalInProgress = true

    let cameraMode = cameraMode
    let reactionVideoDuration = reactionVideoDuration
    let captures = recordingsManager.captures
    let onDismiss = onDismiss

    cleanUp {
      if let reactionVideo = reactionVideoDuration.flatMap({ cameraMode.reactionVideo(duration: $0) }) {
        onDismiss.emit(.success(.reaction(video: reactionVideo, reaction: captures.videos)))
      } else {
        onDismiss.emit(.success(.capture(captures)))
      }
    }
  }

  func cancel(error: CameraError? = nil) {
    guard !isDismissalInProgress else { return }
    // Orphan-clean the previewing photo — it's not in `recordingsManager` yet, so `deleteAll()` won't catch it.
    if case let .previewingPhoto(photo) = state {
      for image in photo.images {
        try? FileManager.default.removeItem(at: image.url)
      }
    }
    isDismissalInProgress = true

    cleanUp()
    do {
      try recordingsManager.deleteAll()
    } catch {
      handleCaptureError(error)
    }

    if let error {
      onDismiss.emit(.failure(error))
    } else {
      // Inform the caller that the camera was possibly closed because of missing permissions.
      let error = !hasVideoPermissions || !hasAudioPermissions ? CameraError.permissionsMissing : .cancelled
      onDismiss.emit(.failure(error))
    }
  }

  // MARK: - Camera Capabilities

  private func updateCameraCapabilities() {
    let cameraDiscovery = AVCaptureDevice.DiscoverySession(
      deviceTypes:
      [.builtInDualCamera,
       .builtInDualWideCamera,
       .builtInTelephotoCamera,
       .builtInTripleCamera,
       .builtInUltraWideCamera,
       .builtInWideAngleCamera],
      mediaType: .video,
      position: .unspecified,
    )

    let allVideoDevices = cameraDiscovery.devices
    hasCamera = allVideoDevices.count > 0
  }

  // MARK: - Camera / Microphone Permissions

  func updatePermissions() async {
    let requiresAudio = configuration.captureType != .photo

    let videoStatus = AVCaptureDevice.authorizationStatus(for: .video)
    var isVideoAuthorized = videoStatus == .authorized

    let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    var isAudioAuthorized = !requiresAudio || audioStatus == .authorized

    if videoStatus == .notDetermined {
      isVideoAuthorized = await AVCaptureDevice.imgly.requestAccess(for: .video)
    }

    if requiresAudio, audioStatus == .notDetermined {
      isAudioAuthorized = await AVCaptureDevice.imgly.requestAccess(for: .audio)
    }

    hasVideoPermissions = isVideoAuthorized
    hasAudioPermissions = isAudioAuthorized

    if !isVideoAuthorized {
      alertState = .cameraPermissions {
        self.cancel()
      }
    } else if requiresAudio, !isAudioAuthorized {
      alertState = .microphonePermissions {
        self.cancel()
      }
    }
  }

  // MARK: - Camera Settings

  let countdownTimer = CountdownTimer()

  @Published var countdownMode = CountdownMode.disabled

  private func cameraModeUpdated(_ cameraMode: CameraMode, _ previousValue: CameraMode?) {
    captureService.setCameraMode(cameraMode)
    do {
      try interactor?.setCameraLayout(cameraMode.rect1, cameraMode.rect2)

      // This should have some neater logic, but basically, when switching between different layouts/positions in
      // reactions we want to avoid flashing black rectangles at the user.
      switch (cameraMode, previousValue) {
      case (.reaction, .reaction):
        break
      default:
        try interactor?.purgeBuffers()
      }

      if case let .reaction(_, url, _) = cameraMode {
        configureReactions(url: url)
      } else {
        reactionVideoDuration = nil
        try? interactor?.clearVideo()
      }
    } catch {
      handleEngineError(error)
    }

    // Re-enable the flash in case it was previously activated.
    captureService.setFlash(mode: torchMode)
  }

  private func configureReactions(url: URL) {
    isLoadingAsset = true
    Task { [weak self] in
      defer { self?.isLoadingAsset = false }
      do {
        let video = try await self?.interactor?.loadVideo(url: url)
        self?.reactionVideoDuration = video.map { CMTime(seconds: $0.duration) }
      } catch {
        print("Failed to load reaction video from \(url): \(error)")
        self?.alertState = .failedToLoadVideo {
          self?.cancel(error: .failedToLoadVideo)
        }
      }
    }
  }

  @Published var flashMode = FlashMode.off

  func toggleFlashMode() {
    // The flash can only be used on the back camera
    guard !isFrontBackFlipped, cameraMode.supportsFlash else {
      return
    }
    flashMode.toggle()
    captureService.setFlash(mode: torchMode)
  }

  @Published private(set) var isFrontBackFlipped = false

  func flipCamera() {
    if flashMode != .off {
      captureService.setFlash(mode: .off)
      flashMode = .off
    }
    captureService.flipCamera()
    do {
      try interactor?.purgeBuffers()
    } catch {
      handleEngineError(error)
    }
    isFrontBackFlipped.toggle()
  }

  func swapReactionVideoPosition() {
    guard case let .reaction(layout, url, positionsSwapped) = cameraMode else { return }
    cameraMode = .reaction(layout, video: url, positionsSwapped: !positionsSwapped)
  }

  private var previousZoom: Double?

  func updateZoom(_ zoomFactor: Double) {
    if previousZoom == nil {
      previousZoom = captureService.zoom
    }
    guard let previousZoom else { return }
    let resolvedZoomFactor = previousZoom * zoomFactor
    captureService.zoom = resolvedZoomFactor
  }

  func finishZoom(_ zoomFactor: Double) {
    guard let previousZoom else { return }
    let resolvedZoomFactor = previousZoom * zoomFactor
    captureService.zoom = resolvedZoomFactor
    self.previousZoom = nil
  }

  @Published var isReactionVideoSheetPresented = false

  func pickReactionVideo() {
    isReactionVideoSheetPresented = true
  }

  // MARK: - Streaming

  func retry() {
    state = .preparing
    startStreaming()
  }

  // swiftlint:disable:next cyclomatic_complexity
  func startStreaming() {
    guard cameraStreamTask == nil, !isInitializingStream else { return }
    guard hasCamera else {
      handleCaptureError(CameraCaptureError.noCameraAvailable)
      return
    }

    guard hasVideoPermissions, hasAudioPermissions else {
      handleCaptureError(CameraCaptureError.permissionsMissing)
      return
    }

    Task {
      if self.interactor == nil {
        do {
          isInitializingStream = true
          self.interactor = try await CameraCanvasInteractor(
            settings: settings,
            videoSize: configuration.videoSize,
          )
          DispatchQueue.main.async { [weak self] in
            self?.state = .ready
            if let currentMode = self?.cameraMode {
              self?.cameraModeUpdated(currentMode, nil)
            }
          }
        } catch {
          handleEngineError(error)
          return
        }
      }

      guard let interactor else { return }

      cameraStreamTask = Task {
        // The captureSession resets its properties, including flash state, at the start of each capture. To maintain
        // consistency, we explicitly set the flash to its desired state ('flashMode') after initiating streaming.
        for try await event in captureService.resumeStreaming(with: torchMode) {
          switch event {
          case let .output1Frame(buffer):
            try interactor.updatePixelStreamFill1(buffer: buffer)
            if recordingsManager.currentlyRecordedClipDuration != captureService.currentlyRecordedClipDuration {
              recordingsManager.currentlyRecordedClipDuration = captureService.currentlyRecordedClipDuration
            }

          case let .output2Frame(buffer):
            try interactor.updatePixelStreamFill2(buffer: buffer)

          case let .recording(recordedClip):
            recordingsManager.add(.video(recordedClip))
            recordingsManager.currentlyRecordedClipDuration = nil
            DispatchQueue.main.async { [weak self] in
              guard let self else { return }
              // Order matters: `done()` before any state flip avoids a shutter flash.
              if configuration.captureCount == .single {
                done()
              } else {
                state = .ready
              }
            }
          }
        }
      }
      isInitializingStream = false
    }
  }

  func stopStreaming(callback: (@MainActor () -> Void)? = nil) {
    captureService.pauseStreaming(callback: callback)
    cameraStreamTask?.cancel()
    cameraStreamTask = nil
    do {
      try interactor?.purgeBuffers()
    } catch {
      handleEngineError(error)
    }
  }

  // MARK: - Shutter routing

  func shutterTapped() {
    switch (configuration.captureType, configuration.captureCount) {
    case (.photo, _):
      capturePhoto()
    case (.mixed, _) where activeMixedSubMode == .photo:
      capturePhoto()
    case (.video, _), (.mixed, _):
      toggleRecording()
    }
  }

  func shutterLongPressed() {
    switch (configuration.captureType, configuration.captureCount) {
    case (.video, _):
      startRecording()
    case (.mixed, .multi) where activeMixedSubMode == .video:
      startRecording()
    default:
      break
    }
  }

  func shutterLongPressReleased() {
    switch (configuration.captureType, configuration.captureCount) {
    case (.video, _):
      stopRecording()
    case (.mixed, .multi) where activeMixedSubMode == .video:
      stopRecording()
    default:
      break
    }
  }

  // MARK: - Manage recording state

  func capturePhoto() {
    switch state {
    case .ready:
      guard !isLoadingAsset else { return }
      if countdownMode != .disabled {
        state = .countingDown
        countdownTimer.start(seconds: countdownMode.rawValue) { [weak self] in
          self?.capturePhotoImmediate()
        }
      } else {
        capturePhotoImmediate()
      }
    case .countingDown:
      // Second tap cancels the countdown (mirrors `toggleRecording`).
      countdownTimer.cancel()
      state = .ready
    default:
      break
    }
  }

  private func capturePhotoImmediate() {
    state = .capturingPhoto
    Task { [weak self] in
      guard let self else { return }
      do {
        let images = try await captureService.capturePhoto(flashMode: flashMode)
        guard !isDismissalInProgress else {
          // Cancelled mid-capture — drop the orphan JPEGs since cancel() already cleared the stack.
          for image in images {
            try? FileManager.default.removeItem(at: image.url)
          }
          return
        }
        let photo = Photo(images: images, duration: configuration.photoClipDuration)
        if configuration.showsPhotoPreview {
          // Hold the photo in `.previewingPhoto` until the user confirms or discards.
          // The photo only joins `recordingsManager` on confirm so retry is a clean file delete.
          state = .previewingPhoto(photo)
        } else {
          recordingsManager.add(.photo(photo))
          if configuration.captureCount == .single {
            done()
          } else {
            state = .ready
          }
        }
      } catch {
        handleCaptureError(error)
      }
    }
  }

  func toggleRecording() {
    switch state {
    case .ready:
      if countdownMode != .disabled {
        state = .countingDown
        countdownTimer.start(seconds: countdownMode.rawValue) { [weak self] in
          guard let self else { return }
          startRecording()
        }
      } else {
        startRecording()
      }
    case .countingDown:
      stopRecording()
    case .recording:
      stopRecording()
    default:
      break
    }
  }

  func startRecording() {
    guard state != .recording else { return }
    let remainingDuration = recordingsManager.remainingRecordingDuration
    state = .recording
    captureService.startRecording(remainingRecordingDuration: remainingDuration)
    interactor?.reactionVideoSetPlaying(true)
  }

  func stopRecording() {
    do {
      countdownTimer.cancel()
      // Only reset state if there's actually an active recording/countdown to stop — otherwise
      // backgrounding during `.previewingPhoto` (which calls into here) would clobber the preview.
      let isActiveRecording = [.recording, .countingDown].contains(state)
      if isActiveRecording, !isDismissalInProgress {
        DispatchQueue.main.async { [weak self] in
          self?.state = .ready
        }
      }
      try captureService.stopRecording()
      interactor?.reactionVideoSetPlaying(false)
    } catch {
      handleCaptureError(error)
    }
  }

  func deleteLastRecording() {
    do {
      objectWillChange.send()
      try recordingsManager.deleteLastCapture()
      let currentDuration = recordingsManager.recordedClipsTotalDuration.seconds
      try interactor?.setReactionPlaybackTime(currentDuration)
    } catch {
      handleActionError(error)
    }
  }

  // MARK: - Photo preview

  func confirmPhotoPreview() {
    guard case let .previewingPhoto(photo) = state else { return }
    recordingsManager.add(.photo(photo))
    // Order matters: `done()` before any state flip avoids a preview flash.
    if configuration.captureCount == .single {
      done()
    } else {
      state = .ready
    }
  }

  func discardPhotoPreview() {
    guard case let .previewingPhoto(photo) = state else { return }
    for image in photo.images {
      try? FileManager.default.removeItem(at: image.url)
    }
    state = .ready
  }

  // MARK: - Error handling

  func handleEngineError(_ error: Swift.Error) {
    DispatchQueue.main.async { [weak self] in
      self?.state = .error(.imglyEngineError(error.localizedDescription))
    }
  }

  func handleCaptureError(_ error: Swift.Error) {
    DispatchQueue.main.async { [weak self] in
      self?.state = .error(.captureError(error.localizedDescription))
    }
  }

  func handleActionError(_ error: Swift.Error) {
    alertState = AlertState(
      title: "Error",
      message: error.localizedDescription,
      buttons: [
        .init(title: "OK", action: {}),
      ],
    )
  }
}

// MARK: - Notification handling

extension CameraModel {
  // swiftlint:disable:next cyclomatic_complexity
  private func configureNotificationHandlers() {
    didEnterBackgroundNotificationPublisher = NotificationCenter.default.publisher(
      for: UIApplication.didEnterBackgroundNotification,
      object: nil,
    )
    .sink(receiveValue: { [weak self] _ in
      guard let self else { return }
      stopRecording()
      stopStreaming()
    })

    didBecomeActiveNotificationPublisher = NotificationCenter.default.publisher(
      for: UIApplication.didBecomeActiveNotification,
      object: nil,
    )
    .sink(receiveValue: { [weak self] _ in
      guard let self else { return }
      startStreaming()
    })

    willResignActiveNotificationPublisher = NotificationCenter.default.publisher(
      for: UIApplication.willResignActiveNotification,
      object: nil,
    )
    .sink(receiveValue: { [weak self] _ in
      guard let self else { return }
      stopStreaming()
    })

    captureSessionRuntimeErrorNotificationPublisher = NotificationCenter.default.publisher(
      for: .AVCaptureSessionRuntimeError,
      object: captureService.captureSession,
    )
    .receive(on: DispatchQueue.main)
    .sink(receiveValue: { [weak self] notification in
      guard let self else { return }
      stopStreaming()
      stopRecording()

      var error = CameraCaptureError.unknownCaptureError
      if let nsError = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError {
        let failureReason = nsError.localizedFailureReason ?? ""
        error = .captureError("\(nsError.localizedDescription)\n\(failureReason)")
      }
      handleCaptureError(error)
    })

    captureSessionWasInterruptedNotificationPublisher = NotificationCenter.default.publisher(
      for: .AVCaptureSessionWasInterrupted,
      object: captureService.captureSession,
    )
    .receive(on: DispatchQueue.main)
    .sink(receiveValue: { [weak self] notification in
      guard let self else { return }
      if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
         let reasonIntegerValue = userInfoValue.integerValue,
         let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
        switch reason {
        case .videoDeviceNotAvailableInBackground:
          // We ignore this case because we handle the backgrounding event and there is no need to display an error.
          return
        case .audioDeviceInUseByAnotherClient:
          handleCaptureError(CameraCaptureError.audioDeviceInUseByAnotherClient)
        case .videoDeviceInUseByAnotherClient:
          handleCaptureError(CameraCaptureError.videoDeviceInUseByAnotherClient)
        case .videoDeviceNotAvailableWithMultipleForegroundApps:
          handleCaptureError(CameraCaptureError.videoDeviceNotAvailableWithMultipleForegroundApps)
        case .videoDeviceNotAvailableDueToSystemPressure:
          handleCaptureError(CameraCaptureError.videoDeviceNotAvailableDueToSystemPressure)
        default:
          break
        }
      }
      stopStreaming()
      stopRecording()
    })

    captureSessionInterruptionEndedNotificationPublisher = NotificationCenter.default.publisher(
      for: .AVCaptureSessionInterruptionEnded,
      object: captureService.captureSession,
    )
    .receive(on: DispatchQueue.main)
    .sink(receiveValue: { [weak self] _ in
      guard let self else { return }
      startStreaming()
    })
  }
}

extension CameraModel: CaptureServiceDelegate {
  nonisolated func captureServiceDidStopRecording(_: CaptureService) {
    Task { @MainActor in
      stopRecording()
    }
  }
}
