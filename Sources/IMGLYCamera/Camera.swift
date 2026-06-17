import CoreMedia
@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

/// A camera for capturing videos.
public struct Camera: View {
  @StateObject var camera: CameraModel

  @State private var isShowingDeleteDialog = false
  @State private var isShowingDeleteAllDialog = false

  @ScaledMetric private var recordButtonSize: Double = 82

  @State private var isPhotoFlashing = false
  @State private var hideChromeForCapture = false

  var showsCameraUI: Bool {
    [.ready, .countingDown, .recording, .capturingPhoto].contains(camera.state)
      && !camera.isLoadingAsset
      && !camera.isDismissalInProgress
  }

  var isPreviewingPhoto: Bool {
    if case .previewingPhoto = camera.state { return true }
    return false
  }

  var showsFlashButton: Bool {
    !camera.isFrontBackFlipped && camera.cameraMode.supportsFlash
  }

  var showsPhotoVideoToggle: Bool {
    camera.configuration.captureType == .mixed
      && camera.state == .ready
      && !camera.isLoadingAsset
  }

  var showsFeaturesMenu: Bool {
    guard !camera.isLoadingAsset else { return false }
    switch camera.state {
    case .ready, .capturingPhoto, .previewingPhoto:
      return true
    default:
      return false
    }
  }

  var didRecord: Bool {
    // Single-take auto-dismisses, so the delete and Done buttons would only flash in.
    camera.configuration.captureCount == .multi
      && camera.recordingsManager.hasRecordings
      && ![.countingDown, .recording].contains(camera.state)
  }

  var maxDuration: String {
    camera.recordingsManager.maxTotalDuration.imgly.formattedDurationStringForClip()
  }

  var isRecordButtonDisabled: Bool {
    camera.recordingsManager.hasReachedMaxDuration
      || !showsCameraUI
      || camera.isLoadingAsset
      || camera.state == .capturingPhoto
  }

  var canSwapPositions: Bool {
    !camera.hasRecordings && !camera.isRecording
  }

  /// Creates a camera.
  /// - Parameters:
  ///   - settings: The settings to initialize the underlying engine.
  ///   - config: Customize the camera experience and behavior.
  ///   - onDismiss: When the camera is dismissed, it calls the `onDismiss` and passes a `Result`.
  ///     - If the user has recorded videos, you’ll receive a `.success` result and an array of `Recording`s.
  ///     - If the user exits the camera without recording a video, you’ll get a `.failure` of `CameraError.cancelled`.
  @available(*, deprecated, message: "Use inititalizer with `Result<CameraResult, CameraError>` callback instead.")
  @_disfavoredOverload
  public init(
    _ settings: EngineSettings,
    config: CameraConfiguration = .init(),
    onDismiss: @escaping @MainActor (Result<[Recording], CameraError>) -> Void
  ) {
    // The legacy `Result<[Recording], CameraError>` callback can only carry videos. Force
    // `.video` so a host accidentally configuring `.photo` or `.mixed` doesn't silently
    // receive `.failure(.cancelled)` after capturing photos that landed on disk.
    let safeConfig = config.captureType == .video ? config : config.forcingVideoCaptureType()
    if safeConfig.captureType != config.captureType {
      print("""
      Camera: `captureType: \(config.captureType)` is incompatible with the deprecated \
      `Result<[Recording], CameraError>` callback (it can't carry photos). Forcing \
      `captureType: .video`. Use the `Result<CameraResult, CameraError>` initializer to \
      capture photos.
      """)
    }
    let camera = CameraModel(
      settings,
      config: safeConfig,
      mode: .standard,
      onDismiss: .legacy(onDismiss),
    )

    _camera = StateObject(wrappedValue: camera)
  }

  /// Creates a camera.
  /// - Parameters:
  ///   - settings: The settings to initialize the underlying engine.
  ///   - config: Customize the camera experience and behavior.
  ///   - mode: The mode to launch the camera in. You can use `Camera.isModeSupported(_:)` to check before initializing
  /// the camera. Devices that don't support `.dualCamera` mode will fallback to `.standard` mode.
  ///   - onDismiss: When the camera is dismissed, it calls the `onDismiss` and passes a `Result`.
  ///     - If the user has recorded videos, you’ll receive a `.success` of `CameraResult`.
  ///     - If the user exits the camera without recording a video, you’ll get a `.failure` of `CameraError.cancelled`.
  public init(
    _ settings: EngineSettings,
    config: CameraConfiguration = .init(),
    mode: CameraMode = .standard,
    onDismiss: @escaping @MainActor (Result<CameraResult, CameraError>) -> Void
  ) {
    var mode = mode
    if !Camera.isModeSupported(mode) {
      print("""
      Camera mode \(mode) is not supported on this device. \
      Falling back to `.standard` mode. \
      You can use `Camera.isModeSupported(_:)` to check before initializing the camera.
      """)
      mode = .standard
    }
    let camera = CameraModel(
      settings,
      config: config,
      mode: mode,
      onDismiss: .modern(onDismiss),
    )

    _camera = StateObject(wrappedValue: camera)
  }

  /// Checks if the given camera mode is supported.
  ///
  /// - Parameter mode: The camera mode to check for support.
  /// - Returns: `true` if the given `mode` is supported, otherwise `false`.
  public static func isModeSupported(_ mode: CameraMode) -> Bool {
    switch mode {
    case .dualCamera: CaptureService.isMultiCamSupported
    default: true
    }
  }

  public var body: some View {
    VStack(spacing: 0) {
      VStack {
        CenteredLeadingTrailing {
          if camera.configuration.captureType != .photo {
            TimecodeView()
              .padding(.top)
          }
        } leading: {
          cancelButton
            .padding(.top)
            .padding(.leading)
          Spacer()
        } trailing: {}

        Spacer()
        Spacer()

        HStack {
          // Keep rendered through the photo capture window so the slide-in transition isn't
          // triggered every time we briefly leave `.ready` for a photo. `.preparing` is excluded
          // so the initial entry into `.ready` still animates the menu in.
          if showsFeaturesMenu {
            FeaturesMenuView()
              .transition(.offset(x: -20).combined(with: .opacity))
          }
          Spacer()
        }

        Spacer()

        CenteredLeadingTrailing {
          RecordButton()
            .frame(width: recordButtonSize, height: recordButtonSize)
            .overlay(alignment: .top) {
              Group {
                if camera.recordingsManager.hasReachedMaxDuration {
                  Text(.imgly.localized("ly_img_camera_label_recording_limit \(maxDuration)"))
                    .fixedSize()
                    .offset(x: 0, y: -50)
                    .transition(.offset(x: 0, y: 20).combined(with: .opacity))
                }
              }
              .animation(.spring(), value: camera.recordingsManager.hasReachedMaxDuration)
            }
            .disabled(isRecordButtonDisabled)
        } leading: {
          Spacer()
          if didRecord {
            deleteLastRecordingButton
              .padding(.trailing)
              .transition(.offset(x: -20).combined(with: .opacity))
          }
        } trailing: {
          Spacer()
          if didRecord {
            doneButton
              .padding(.trailing)
              .transition(.offset(x: 20).combined(with: .opacity))
          }
        }
        .tint(camera.configuration.highlightColor)
        .padding(.top, 60)
        .padding(.bottom, 40)
      }
      .opacity(isPreviewingPhoto || camera.isDismissalInProgress || hideChromeForCapture ? 0 : 1)
      .allowsHitTesting(!isPreviewingPhoto && !camera.isDismissalInProgress && !hideChromeForCapture)
      .aspectRatio(9 / 16, contentMode: .fit)
      .overlay {
        countdownView.offset(x: 0, y: -44)
      }
      .background { zoomGesture() }
      .background { cameraCanvas() }
      .animation(.easeInOut(duration: 0.3), value: camera.state)
      // Animation when deleting a clip
      .animation(.easeInOut(duration: 0.3), value: camera.recordingsManager.captures.count)
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .overlay { photoPreviewOverlay }
    .overlay(alignment: .bottom) { bottomButtons() }
    .overlay { photoFlashOverlay }
    .background { Color.black.ignoresSafeArea() }
    .environment(\.colorScheme, .dark)
    .environmentObject(camera)
    .environmentObject(camera.recordingsManager)
    .task {
      await camera.updatePermissions()
      camera.startStreaming()
    }
    .onChange(of: camera.state) { newState in
      updatePhotoFlash(for: newState)
      updateChromeForCapture(for: newState)
    }
    .imgly.onDismiss {
      camera.cancel(error: .cancelled)
    }
    .imgly.alert($camera.alertState)
  }

  @ViewBuilder private var photoFlashOverlay: some View {
    Color.white
      .ignoresSafeArea()
      .opacity(isPhotoFlashing ? 1 : 0)
      .allowsHitTesting(false)
  }

  @ViewBuilder private var photoPreviewOverlay: some View {
    if case let .previewingPhoto(photo) = camera.state {
      PhotoPreviewCanvas(photo: photo, layoutMode: camera.cameraMode.layoutMode)
        .transition(.opacity)
    }
  }

  private func isPreviewingPhoto(in state: CameraModel.CameraState) -> Bool {
    if case .previewingPhoto = state { return true }
    return false
  }

  // Hide the camera chrome instantly when capture starts so the white flash doesn't reveal
  // it fading away. Restore once we leave the capturing/previewing window.
  private func updateChromeForCapture(for newState: CameraModel.CameraState) {
    if newState == .capturingPhoto, !hideChromeForCapture {
      var transaction = Transaction()
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        hideChromeForCapture = true
      }
    } else if hideChromeForCapture, newState != .capturingPhoto, !isPreviewingPhoto(in: newState) {
      hideChromeForCapture = false
    }
  }

  // Capture flips the flash on instantly; the preview state fades it out. Discarding the
  // preview (preview → ready) clears it without animation so no cross-fade lingers.
  private func updatePhotoFlash(for newState: CameraModel.CameraState) {
    if newState == .capturingPhoto {
      var transaction = Transaction()
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        isPhotoFlashing = true
      }
    } else if isPhotoFlashing {
      if case .previewingPhoto = newState {
        withAnimation(.easeOut(duration: 0.35)) {
          isPhotoFlashing = false
        }
      } else {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
          isPhotoFlashing = false
        }
      }
    }
  }

  @ViewBuilder private func zoomGesture() -> some View {
    if showsCameraUI {
      Rectangle()
        .fill(.clear)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
          camera.flipCamera()
        }
        .gesture(
          MagnificationGesture()
            .onChanged { camera.updateZoom($0) }
            .onEnded { camera.finishZoom($0) },
        )
    }
  }

  @ViewBuilder private func cameraCanvas() -> some View {
    switch camera.state {
    case .preparing:
      ProgressView()
    case let .error(error):
      CameraErrorView(error: error) {
        camera.retry()
      }
    default:
      if let interactor = camera.interactor {
        CameraCanvasView(interactor: interactor)
          .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
          .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
          .opacity(camera.shouldShowCamera ? 1 : 0)
          .overlay {
            if camera.isLoadingAsset {
              ProgressView()
            }
          }
      }
    }
  }

  @ViewBuilder private func bottomButtons() -> some View {
    if isPreviewingPhoto {
      PhotoPreviewActions(
        onBack: { camera.discardPhotoPreview() },
        onDone: { camera.confirmPhotoPreview() },
      )
      .padding(.horizontal)
      .padding(.bottom, 4)
      .transition(.opacity)
    } else if showsCameraUI {
      HStack {
        flashButton
          .opacity(showsFlashButton ? 1 : 0)
        Spacer()
        if case .reaction = camera.cameraMode, canSwapPositions {
          swapPlaceButton
            .disabled(isRecordButtonDisabled)
            .opacity(camera.isLoadingAsset ? 0.8 : 1)
        } else if showsPhotoVideoToggle {
          PhotoVideoToggle()
        }
        Spacer()
        flipButton
      }
      .padding(.horizontal)
      .padding(.bottom, 4)
    }
  }
}

// MARK: -

struct Camera_Previews: PreviewProvider {
  static var previews: some View {
    let engineSettings = EngineSettings(license: "")
    Camera(engineSettings) { _ in }
  }
}

// MARK: -

extension Camera {
  @ViewBuilder var countdownView: some View {
    HStack {
      if camera.state == .countingDown {
        CountdownTimerView(countdownTimer: camera.countdownTimer)
          .transition(.scale.combined(with: .opacity))
      }
    }
    .animation(.easeInOut(duration: 0.2).delay(camera.state != .countingDown ? 0.4 : 0), value: camera.state)
  }

  @ViewBuilder var cancelButton: some View {
    Button {
      if camera.recordingsManager.hasRecordings || camera.state == .recording {
        isShowingDeleteAllDialog = true
      } else {
        camera.cancel()
      }
    } label: {
      Label {
        Text(.imgly.localized("ly_img_camera_button_close"))
      } icon: {
        Image(systemName: "xmark")
      }
      .labelStyle(.iconOnly)
    }
    .buttonStyle(CameraToolButtonStyle())
    .confirmationDialog(
      Text(.imgly.localized("ly_img_camera_dialog_delete_recordings_title")),
      isPresented: $isShowingDeleteAllDialog,
      titleVisibility: .visible,
    ) {
      Button(role: .destructive) {
        camera.cancel()
      } label: {
        Text(.imgly.localized("ly_img_camera_dialog_delete_recordings_button_confirm"))
      }
      Button(role: .cancel) {
        isShowingDeleteAllDialog = false
      } label: {
        Text(.imgly.localized("ly_img_camera_dialog_delete_recordings_button_dismiss"))
      }
    } message: {
      Text(.imgly.localized("ly_img_camera_dialog_delete_recordings_text"))
    }
  }

  @ViewBuilder var deleteLastRecordingButton: some View {
    Button {
      isShowingDeleteDialog = true
    } label: {
      Label {
        Text(.imgly.localized("ly_img_camera_button_delete_last_recording"))
      } icon: {
        Image(systemName: "xmark.square.fill")
      }
      .labelStyle(.iconOnly)
    }
    .buttonStyle(CameraActionButtonStyle(style: .delete))
    .confirmationDialog(
      Text(.imgly.localized("ly_img_camera_dialog_delete_last_recording_title")),
      isPresented: $isShowingDeleteDialog,
      titleVisibility: .visible,
    ) {
      Button(role: .destructive) {
        camera.deleteLastRecording()
      } label: {
        Text(.imgly.localized("ly_img_camera_dialog_delete_last_recording_button_confirm"))
      }
      Button(role: .cancel) {
        isShowingDeleteDialog = false
      } label: {
        Text(.imgly.localized("ly_img_camera_dialog_delete_last_recording_button_dismiss"))
      }
    } message: {
      Text(.imgly.localized("ly_img_camera_dialog_delete_last_recording_text"))
    }
  }

  @ViewBuilder var doneButton: some View {
    Button {
      HapticsHelper.shared.cameraSelectFeature()
      camera.done()
    } label: {
      Label {
        Text(.imgly.localized("ly_img_camera_button_continue"))
      } icon: {
        Image(systemName: "arrow.forward")
      }
      .labelStyle(.iconOnly)
    }
    .buttonStyle(CameraActionButtonStyle(style: .default))
  }

  @ViewBuilder var flipButton: some View {
    Button {
      HapticsHelper.shared.cameraSelectFeature()
      camera.flipCamera()
    } label: {
      Image(systemName: "arrow.triangle.2.circlepath")
        .rotationEffect(camera.isFrontBackFlipped ? .degrees(180) : .zero)
        .animation(.imgly.flip.delay(0.1), value: camera.isFrontBackFlipped)
        .accessibilityLabel(Text(.imgly.localized("ly_img_camera_button_flip_camera")))
    }
    .buttonStyle(CameraToolButtonStyle())
  }

  @ViewBuilder var swapPlaceButton: some View {
    Button {
      HapticsHelper.shared.cameraSelectFeature()
      camera.swapReactionVideoPosition()
    } label: {
      Image(systemName: "rectangle.2.swap")
        .accessibilityLabel(Text(.imgly.localized("ly_img_camera_button_swap_positions")))
    }
    .buttonStyle(CameraToolButtonStyle())
  }

  @ViewBuilder var flashButton: some View {
    Button {
      HapticsHelper.shared.cameraSelectFeature()
      camera.toggleFlashMode()
    } label: {
      // Photo mode shows the strobe (bolt) symbol since the flash fires per capture;
      // video mode shows the flashlight symbol since the LED runs as a continuous torch.
      switch (camera.flashMode, camera.isVideoModeActive) {
      case (.off, false):
        Image(systemName: "bolt.slash.fill")
      case (.on, false):
        Image(systemName: "bolt.fill")
      case (.off, true):
        // `flashlight.slash` is iOS 17+, so use a custom symbol template for iOS 16 parity.
        Image("custom.flashlight.slash", bundle: .module)
      case (.on, true):
        Image(systemName: "flashlight.on.fill")
      }
    }
    .accessibilityLabel(Text(.imgly.localized("ly_img_camera_button_toggle_flash")))
    .buttonStyle(CameraToolButtonStyle())
  }
}
