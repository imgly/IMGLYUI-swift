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

  func callAsFunction(_ result: Result<[Recording], CameraError>, _ reactionVideo: Recording? = nil) {
    switch (self, result, reactionVideo) {
    case let (.legacy(callback), .success(recordings), .some(reactionVideo)):
      callback(.success([reactionVideo] + recordings))

    case let (.legacy(callback), _, _):
      callback(result)

    case let (.modern(callback), .failure(error), _):
      callback(.failure(error))

    case let (.modern(callback), .success(recordings), .some(reactionVideo)):
      callback(.success(.reaction(video: reactionVideo, reaction: recordings)))

    case let (.modern(callback), .success(recordings), .none):
      callback(.success(.recording(recordings)))
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

  private let captureService = CaptureService()
  private let settings: EngineSettings

  // MARK: - State

  enum CameraState: Equatable {
    case preparing
    case ready
    case countingDown
    case recording
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

  var hasRecordings: Bool {
    !recordingsManager.clips.isEmpty
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

  // Property to track if dismissal is already in progress (prevents double cleanup)
  private var isDismissalInProgress = false

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
    let clips = recordingsManager.clips
    let onDismiss = onDismiss
    cleanUp {
      let reactionVideo = reactionVideoDuration.flatMap { cameraMode.reactionVideo(duration: $0) }
      onDismiss(.success(clips), reactionVideo)
    }
  }

  func cancel(error: CameraError? = nil) {
    guard !isDismissalInProgress else { return }
    isDismissalInProgress = true

    cleanUp()
    do {
      try recordingsManager.deleteAll()
    } catch {
      handleCaptureError(error)
    }

    if let error {
      onDismiss(.failure(error))
    } else {
      // Inform the caller that the camera was possibly closed because of missing permissions.
      let error = !hasVideoPermissions || !hasAudioPermissions ? CameraError.permissionsMissing : .cancelled
      onDismiss(.failure(error))
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
    let videoStatus = AVCaptureDevice.authorizationStatus(for: .video)
    var isVideoAuthorized = videoStatus == .authorized

    let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    var isAudioAuthorized = audioStatus == .authorized

    if videoStatus == .notDetermined {
      isVideoAuthorized = await AVCaptureDevice.imgly.requestAccess(for: .video)
    }

    if audioStatus == .notDetermined {
      isAudioAuthorized = await AVCaptureDevice.imgly.requestAccess(for: .audio)
    }

    hasVideoPermissions = isVideoAuthorized
    hasAudioPermissions = isAudioAuthorized

    if !isVideoAuthorized {
      alertState = .cameraPermissions {
        self.cancel()
      }
    } else if !isAudioAuthorized {
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
    captureService.setFlash(mode: flashMode)
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
    captureService.setFlash(mode: flashMode)
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
        for try await event in captureService.resumeStreaming(with: flashMode) {
          switch event {
          case let .output1Frame(buffer):
            try interactor.updatePixelStreamFill1(buffer: buffer)
            if recordingsManager.currentlyRecordedClipDuration != captureService.currentlyRecordedClipDuration {
              recordingsManager.currentlyRecordedClipDuration = captureService.currentlyRecordedClipDuration
            }

          case let .output2Frame(buffer):
            try interactor.updatePixelStreamFill2(buffer: buffer)

          case let .recording(recordedClip):
            recordingsManager.add(recordedClip)
            recordingsManager.currentlyRecordedClipDuration = nil
            DispatchQueue.main.async { [weak self] in
              self?.state = .ready
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

  // MARK: - Manage recording state

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
      DispatchQueue.main.async { [weak self] in
        self?.state = .ready
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
      try recordingsManager.deleteLastRecording()
      let currentDuration = recordingsManager.recordedClipsTotalDuration.seconds
      try interactor?.setReactionPlaybackTime(currentDuration)
    } catch {
      handleActionError(error)
    }
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
