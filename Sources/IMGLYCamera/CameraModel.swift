import AVFoundation
import Combine
import CoreMedia
import Foundation
import SwiftUI
@_spi(Internal) import IMGLYCoreUI

/// Provides camera state and functionality to the `Camera`.
/// - Manages the `CaptureService`.
/// - Manages the `CameraCanvasInteractor` that provides the `CameraCanvasView` and interfaces with the `IMGLYEngine`.
@MainActor
final class CameraModel: ObservableObject {
  let configuration: CameraConfiguration
  let recordingsManager: RecordingsManager
  let isMultiCamSupported = AVCaptureMultiCamSession.isMultiCamSupported

  private var onDismiss: (Result<[Recording], CameraError>) -> Void

  private(set) var interactor: CameraCanvasInteractor?
  private var cameraStreamTask: Task<Void, Error>?
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

  @Published private(set) var hasVideoPermissions = false
  @Published private(set) var hasAudioPermissions = false
  @Published var alertState: AlertState?

  // MARK: - Lifecycle

  init(
    _ settings: EngineSettings,
    config: CameraConfiguration = .init(),
    cameraMode: CameraMode = .standard,
    onDismiss: @escaping (Result<[Recording], CameraError>) -> Void
  ) {
    self.onDismiss = onDismiss
    self.settings = settings
    self.cameraMode = cameraMode
    configuration = config
    recordingsManager = RecordingsManager(configuration: configuration)
    configureNotificationHandlers()
    updateCameraCapabilities()
  }

  private func cleanUp() {
    stopRecording()
    stopStreaming()
    interactor?.destroyEngine()
  }

  // MARK: - Callback

  func done() {
    cleanUp()
    onDismiss(.success(recordingsManager.clips))
  }

  func cancel() {
    cleanUp()
    do {
      try recordingsManager.deleteAll()
    } catch {
      handleCaptureError(error)
    }
    // Inform the caller that the camera was possibly closed because of missing permissions.
    let error = !hasVideoPermissions || !hasAudioPermissions ? CameraError.permissionsMissing : .cancelled
    onDismiss(.failure(error))
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
      position: .unspecified
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
      isVideoAuthorized = await AVCaptureDevice.requestAccess(for: .video)
    }

    if audioStatus == .notDetermined {
      isAudioAuthorized = await AVCaptureDevice.requestAccess(for: .audio)
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
  @Published var cameraMode: CameraMode = .standard {
    didSet {
      cameraModeUpdated(cameraMode)
    }
  }

  private func cameraModeUpdated(_ cameraMode: CameraMode) {
    captureService.setCameraMode(cameraMode)
    do {
      try interactor?.purgeBuffers()
      try interactor?.setCameraLayout(cameraMode.rect1, cameraMode.rect2)
    } catch {
      handleEngineError(error)
    }

    // Re-enable the flash in case it was previously activated.
    captureService.setFlash(mode: flashMode)
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
            videoSize: configuration.videoSize
          )
          try self.interactor?.setCameraLayout(cameraMode.rect1, cameraMode.rect2)
          DispatchQueue.main.async { [weak self] in
            self?.state = .ready
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

  func stopStreaming() {
    captureService.pauseStreaming()
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
  }

  func stopRecording() {
    do {
      countdownTimer.cancel()
      DispatchQueue.main.async { [weak self] in
        self?.state = .ready
      }
      try captureService.stopRecording()
    } catch {
      handleCaptureError(error)
    }
  }

  // MARK: - Error handling

  func handleEngineError(_ error: Error) {
    DispatchQueue.main.async { [weak self] in
      self?.state = .error(.imglyEngineError(error.localizedDescription))
    }
  }

  func handleCaptureError(_ error: Error) {
    DispatchQueue.main.async { [weak self] in
      self?.state = .error(.captureError(error.localizedDescription))
    }
  }

  func handleActionError(_ error: Error) {
    alertState = AlertState(
      title: "Error",
      message: error.localizedDescription,
      buttons: [
        .init(title: "OK", action: {}),
      ]
    )
  }
}

// MARK: - Notification handling

extension CameraModel {
  // swiftlint:disable:next cyclomatic_complexity
  private func configureNotificationHandlers() {
    didEnterBackgroundNotificationPublisher = NotificationCenter.default.publisher(
      for: UIApplication.didEnterBackgroundNotification,
      object: nil
    )
    .sink(receiveValue: { [weak self] _ in
      guard let self else { return }
      stopRecording()
      stopStreaming()
    })

    didBecomeActiveNotificationPublisher = NotificationCenter.default.publisher(
      for: UIApplication.didBecomeActiveNotification,
      object: nil
    )
    .sink(receiveValue: { [weak self] _ in
      guard let self else { return }
      startStreaming()
    })

    willResignActiveNotificationPublisher = NotificationCenter.default.publisher(
      for: UIApplication.willResignActiveNotification,
      object: nil
    )
    .sink(receiveValue: { [weak self] _ in
      guard let self else { return }
      stopStreaming()
    })

    captureSessionRuntimeErrorNotificationPublisher = NotificationCenter.default.publisher(
      for: .AVCaptureSessionRuntimeError,
      object: captureService.captureSession
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
      object: captureService.captureSession
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
      object: captureService.captureSession
    )
    .sink(receiveValue: { [weak self] _ in
      guard let self else { return }
      startStreaming()
    })
  }
}
