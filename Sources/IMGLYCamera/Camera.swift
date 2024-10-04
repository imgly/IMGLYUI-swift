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

  @Environment(\.imglyAssetLibrary) private var anyAssetLibrary
  var assetLibrary: some AssetLibrary {
    anyAssetLibrary ?? AnyAssetLibrary(erasing: DefaultAssetLibrary())
  }

  var showsCameraUI: Bool {
    [.ready, .countingDown, .recording].contains(camera.state) && !camera.isLoadingAsset
  }

  var recordedDuration: CMTime {
    camera.recordingsManager.recordedClipsTotalDuration
      + (camera.recordingsManager.currentlyRecordedClipDuration ?? .zero)
  }

  var showsFlashButton: Bool {
    !camera.isFrontBackFlipped && camera.cameraMode.supportsFlash
  }

  var didRecord: Bool {
    camera.recordingsManager.hasRecordings && ![.countingDown, .recording].contains(camera.state)
  }

  var maxDuration: String {
    camera.recordingsManager.maxTotalDuration.imgly.formattedDurationStringForClip()
  }

  var isRecordButtonDisabled: Bool {
    camera.recordingsManager.hasReachedMaxDuration || !showsCameraUI || camera.isLoadingAsset
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
    onDismiss: @escaping (Result<[Recording], CameraError>) -> Void
  ) {
    let camera = CameraModel(
      settings,
      config: config,
      mode: .standard,
      onDismiss: .legacy(onDismiss)
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
    onDismiss: @escaping (Result<CameraResult, CameraError>) -> Void
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
      onDismiss: .modern(onDismiss)
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
          TimecodeView(
            isRecording: camera.isRecording,
            recordedDuration: recordedDuration,
            maxDuration: camera.reactionVideoDuration ?? camera.configuration.maxTotalDuration,
            recordingColor: camera.configuration.recordingColor
          )
          .padding(.top)
        } leading: {
          cancelButton
            .padding(.top)
            .padding(.leading)
          Spacer()
        } trailing: {}

        Spacer()
        Spacer()

        HStack {
          if camera.state == .ready, !camera.isLoadingAsset {
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
                  Text("Recording limit is \(maxDuration)")
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
      .aspectRatio(9 / 16, contentMode: .fit)
      .overlay {
        countdownView.offset(x: 0, y: -44)
      }
      .background { zoomGesture() }
      .background { cameraCanvas() }
      .animation(.easeInOut(duration: 0.3), value: camera.state)
      // Animation when deleting a clip
      .animation(.easeInOut(duration: 0.3), value: camera.recordingsManager.clips.count)
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .overlay(alignment: .bottom) { bottomButtons() }
    .background { Color.black.ignoresSafeArea() }
    .environment(\.colorScheme, .dark)
    .environmentObject(camera)
    .environmentObject(camera.recordingsManager)
    .task {
      await camera.updatePermissions()
      camera.startStreaming()
    }
    .alert($camera.alertState)
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
            .onEnded { camera.finishZoom($0) }
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
          .opacity(camera.isLoadingAsset ? 0 : 1)
          .overlay {
            if camera.isLoadingAsset {
              ProgressView()
            }
          }
      }
    }
  }

  @ViewBuilder private func bottomButtons() -> some View {
    if showsCameraUI {
      HStack {
        flashButton
          .opacity(showsFlashButton ? 1 : 0)
        Spacer()
        if case .reaction = camera.cameraMode, canSwapPositions {
          swapPlaceButton
            .disabled(isRecordButtonDisabled)
            .opacity(camera.isLoadingAsset ? 0.8 : 1)
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
      Image(systemName: "xmark")
    }
    .buttonStyle(CameraToolButtonStyle())
    .confirmationDialog(
      "Delete all clips and close the camera?\nThis cannot be undone.",
      isPresented: $isShowingDeleteAllDialog,
      titleVisibility: .visible
    ) {
      Button("Delete All", role: .destructive) {
        camera.cancel()
      }
      Button("Cancel", role: .cancel) {
        isShowingDeleteAllDialog = false
      }
    }
  }

  @ViewBuilder var deleteLastRecordingButton: some View {
    Button {
      isShowingDeleteDialog = true
    } label: {
      Image(systemName: "xmark.square.fill")
    }
    .buttonStyle(CameraActionButtonStyle(style: .delete))
    .confirmationDialog(
      "Delete your last recorded clip? This cannot be undone.",
      isPresented: $isShowingDeleteDialog,
      titleVisibility: .visible
    ) {
      Button("Delete Last Recording", role: .destructive) {
        camera.deleteLastRecording()
      }
      Button("Cancel", role: .cancel) {
        isShowingDeleteDialog = false
      }
    }
  }

  @ViewBuilder var doneButton: some View {
    Button {
      HapticsHelper.shared.cameraSelectFeature()
      camera.done()
    } label: {
      Image(systemName: "arrow.forward")
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
        .accessibilityLabel(camera.isFrontBackFlipped ? "Flip to back camera" : "Flip to front camera")
    }
    .buttonStyle(CameraToolButtonStyle())
  }

  @ViewBuilder var swapPlaceButton: some View {
    Button {
      HapticsHelper.shared.cameraSelectFeature()
      camera.swapReactionVideoPosition()
    } label: {
      Image(systemName: "rectangle.2.swap")
        .accessibilityLabel("Swap video and camera position")
    }
    .buttonStyle(CameraToolButtonStyle())
  }

  @ViewBuilder var flashButton: some View {
    Button {
      HapticsHelper.shared.cameraSelectFeature()
      camera.toggleFlashMode()
    } label: {
      switch camera.flashMode {
      case .off:
        Image(systemName: "bolt.slash.fill")
          .accessibilityLabel("Flash is off")
      case .on:
        Image(systemName: "bolt.fill")
          .accessibilityLabel("Flash is on")
      }
    }
    .buttonStyle(CameraToolButtonStyle())
  }
}
