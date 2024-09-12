import AVFoundation
import Foundation
import UIKit

/// Manages the camera and microphone device state and provides a stream of `CaptureStreamUpdate`s.
final class CaptureService: NSObject, @unchecked Sendable {
  var videoOrientation: AVCaptureVideoOrientation = .portrait

  private(set) var isStreaming = false
  private(set) var isRecording = false

  private(set) var isFlipped = false
  private(set) var cameraMode: CameraMode = .standard

  var currentlyRecordedClipDuration: CMTime?

  private let videoFileType = AVFileType.mp4
  private let videoFileExtension = "mp4"
  private let videoCodec = AVVideoCodecType.h264

  // MARK: -

  private lazy var queue = DispatchQueue(label: "ly.img.camera", qos: .userInteractive)

  // This is either an AVCaptureSession or an AVCaptureMultiCamSession, depending on the device.
  let captureSession: AVCaptureSession
  private var streamingContinuation: AsyncThrowingStream<CaptureStreamUpdate, Error>.Continuation?

  private var camera1Input: AVCaptureDeviceInput?
  private var camera2Input: AVCaptureDeviceInput?
  private var audioInput: AVCaptureDeviceInput?

  private var camera1Connection: AVCaptureConnection?
  private var camera2Connection: AVCaptureConnection?

  private let videoOutput1 = AVCaptureVideoDataOutput()
  private let videoOutput2 = AVCaptureVideoDataOutput()
  private let audioOutput = AVCaptureAudioDataOutput()

  private var recorder1: VideoRecorder?
  private var recorder2: VideoRecorder?

  private var remainingRecordingDuration: CMTime = .positiveInfinity

  // MARK: -

  override init() {
    captureSession = AVCaptureMultiCamSession.isMultiCamSupported ? AVCaptureMultiCamSession() : AVCaptureSession()

    super.init()

    // Don't let the capture session use the shared app audio session. Otherwise, miniaudio
    // (the engine's audio backend) can't track the interruption and has an incorrect state.
    // https://stackoverflow.com/a/21196673/10324858
    // Another way to solve this would be to reconfigure the shared session for playback again
    // after we're done with recording.

    // This solution has a drawback:
    // Not using the app’s default session prevents us from enabling haptic feedback while recording.
    // See `HapticsHelper` for details.

    captureSession.usesApplicationAudioSession = false

    configure()
    rewireConnections(cameraMode: cameraMode, isFlipped: isFlipped)
  }

  private func configure() {
    captureSession.beginConfiguration()

    if captureSession.canAddOutput(videoOutput1) {
      captureSession.addOutputWithNoConnections(videoOutput1)
    }

    if captureSession.canAddOutput(videoOutput2) {
      captureSession.addOutputWithNoConnections(videoOutput2)
    }

    if captureSession.canAddOutput(audioOutput) {
      captureSession.addOutputWithNoConnections(audioOutput)
    }

    videoOutput1.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    videoOutput2.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

    camera1Input = backCameraInput()
    camera2Input = frontCameraInput()

    if let input = microphoneInput(),
       captureSession.canAddInput(input) {
      audioInput = input
      captureSession.addInputWithNoConnections(input)
      let connection = AVCaptureConnection(inputPorts: input.ports, output: audioOutput)
      captureSession.addConnection(connection)
    }

    videoOutput1.setSampleBufferDelegate(self, queue: queue)
    videoOutput2.setSampleBufferDelegate(self, queue: queue)
    audioOutput.setSampleBufferDelegate(self, queue: queue)

    captureSession.commitConfiguration()
  }

  private func frontCameraInput() -> AVCaptureDeviceInput? {
    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
      return nil
    }
    return try? AVCaptureDeviceInput(device: device)
  }

  private func backCameraInput() -> AVCaptureDeviceInput? {
    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
      return nil
    }
    return try? AVCaptureDeviceInput(device: device)
  }

  private func microphoneInput() -> AVCaptureDeviceInput? {
    guard let device = AVCaptureDevice.default(for: .audio) else {
      return nil
    }
    return try? AVCaptureDeviceInput(device: device)
  }

  // MARK: - Connections

  func setCameraMode(_ cameraMode: CameraMode) {
    guard cameraMode != self.cameraMode else { return }
    if cameraMode.isMultiCamera, !AVCaptureMultiCamSession.isMultiCamSupported {
      return
    }
    rewireConnections(cameraMode: cameraMode, isFlipped: isFlipped)
  }

  func flipCamera() {
    rewireConnections(cameraMode: cameraMode, isFlipped: !isFlipped)
  }

  private func rewireConnections(cameraMode: CameraMode, isFlipped: Bool) {
    queue.async { [weak self] in
      guard let self else { return }

      defer {
        self.cameraMode = cameraMode
        self.isFlipped = isFlipped
      }

      captureSession.beginConfiguration()

      if let camera1Connection {
        captureSession.removeConnection(camera1Connection)
        self.camera1Connection = nil
      }

      if let camera2Connection {
        captureSession.removeConnection(camera2Connection)
        self.camera2Connection = nil
      }

      if let input = isFlipped ? camera2Input : camera1Input {
        if !AVCaptureMultiCamSession.isMultiCamSupported,
           let oldInput = isFlipped ? camera1Input : camera2Input {
          // If we don’t have multicam support, we must remove the old input.
          captureSession.removeInput(oldInput)
        }

        // For multicam sessions, this is skipped after the first time.
        // For single cam sessions, the connection is re-established every time.
        if captureSession.canAddInput(input) {
          captureSession.addInputWithNoConnections(input)
        }

        let connection = AVCaptureConnection(inputPorts: input.ports, output: videoOutput1)
        camera1Connection = connection
        connection.isVideoMirrored = input.device.position == .front
        connection.videoOrientation = videoOrientation
        captureSession.addConnection(connection)
      }

      if AVCaptureMultiCamSession.isMultiCamSupported, cameraMode.isMultiCamera {
        if let input = isFlipped ? camera1Input : camera2Input {
          if captureSession.canAddInput(input) {
            captureSession.addInputWithNoConnections(input)
          }
          let connection = AVCaptureConnection(inputPorts: input.ports, output: videoOutput2)
          camera2Connection = connection
          connection.isVideoMirrored = input.device.position == .front
          connection.videoOrientation = videoOrientation
          captureSession.addConnection(connection)
        }
      }

      captureSession.commitConfiguration()
    }
  }

  // MARK: -

  func resumeStreaming(with flashMode: FlashMode) -> AsyncThrowingStream<CaptureStreamUpdate, Error> {
    startRunning()
    setFlash(mode: flashMode)
    isStreaming = true
    return .init { continuation in
      streamingContinuation = continuation

      continuation.onTermination = { [weak self] _ in
        guard let self else { return }
        stopRunning()
      }
    }
  }

  func pauseStreaming() {
    stopRunning()
    isStreaming = false
  }

  private func startRunning() {
    queue.async { [weak self] in
      guard let self else { return }
      captureSession.startRunning()
    }
  }

  private func stopRunning() {
    queue.async { [weak self] in
      guard let self else { return }
      captureSession.stopRunning()
    }
  }

  // MARK: -

  func startRecording(remainingRecordingDuration: CMTime = .positiveInfinity) {
    guard remainingRecordingDuration > .zero else { return }

    guard let audioSettings = audioSettings(),
          let output1Settings = output1Settings() else { return }
    queue.async { [weak self] in
      guard let self else { return }

      let fileURL1 = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString + "." + videoFileExtension)
      recorder1 = VideoRecorder(
        audioSettings: audioSettings,
        videoSettings: output1Settings,
        videoTransform: CGAffineTransformIdentity
      )
      recorder1?.startRecording(to: fileURL1, fileType: videoFileType)
      recorder2 = nil

      if cameraMode != .standard {
        guard let output2Settings = output2Settings() else { return }
        let fileURL2 = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString + "." + videoFileExtension)
        recorder2 = VideoRecorder(
          audioSettings: audioSettings,
          videoSettings: output2Settings,
          videoTransform: CGAffineTransformIdentity
        )
        recorder2?.startRecording(to: fileURL2, fileType: videoFileType)
      }
      self.remainingRecordingDuration = remainingRecordingDuration
      isRecording = true
    }
  }

  func stopRecording() throws {
    guard isRecording else { return }
    isRecording = false

    if let recorder1, let recorder2 {
      Task {
        async let (firstVideoURL, recordedDuration) = recorder1.stopRecording()
        async let (secondVideoURL, _) = recorder2.stopRecording()

        let recordedClip = try await Recording(
          videos: [
            .init(url: firstVideoURL, rect: cameraMode.rect1),
            .init(url: secondVideoURL, rect: cameraMode.rect2 ?? .zero),
          ],
          duration: recordedDuration
        )
        self.streamingContinuation?.yield(.recording(recordedClip))
        currentlyRecordedClipDuration = nil
      }
    } else if let recorder1 {
      Task {
        async let (firstVideoURL, recordedDuration) = recorder1.stopRecording()

        let recordedClip = try await Recording(
          videos: [
            .init(url: firstVideoURL, rect: cameraMode.rect1),
          ],
          duration: recordedDuration
        )
        self.streamingContinuation?.yield(.recording(recordedClip))
        currentlyRecordedClipDuration = nil
      }
    }
  }

  private func audioSettings() -> [String: NSObject]? {
    audioOutput.recommendedAudioSettingsForAssetWriter(
      writingTo: videoFileType
    ) as? [String: NSObject]
  }

  private func output1Settings() -> [String: NSObject]? {
    videoOutput1.recommendedVideoSettings(
      forVideoCodecType: videoCodec,
      assetWriterOutputFileType: videoFileType
    ) as? [String: NSObject]
  }

  private func output2Settings() -> [String: NSObject]? {
    videoOutput2.recommendedVideoSettings(
      forVideoCodecType: videoCodec,
      assetWriterOutputFileType: videoFileType
    ) as? [String: NSObject]
  }

  // MARK: - Hardware Features

  var zoom: Double {
    get {
      guard let device = isFlipped ? camera2Input?.device : camera1Input?.device else { return 1 }
      return device.videoZoomFactor
    }
    set {
      guard let device = isFlipped ? camera2Input?.device : camera1Input?.device else { return }
      let minZoom = device.minAvailableVideoZoomFactor
      let maxZoom = device.maxAvailableVideoZoomFactor
      queue.async {
        let resolvedZoomFactor = max(minZoom, min(maxZoom, newValue))
        do {
          try device.lockForConfiguration()
          device.videoZoomFactor = resolvedZoomFactor
          device.unlockForConfiguration()
        } catch {
          print(error.localizedDescription)
        }
      }
    }
  }

  func setFlash(mode: FlashMode) {
    guard let device = camera1Input?.device, device.hasTorch else { return }

    queue.async {
      do {
        try device.lockForConfiguration()
        switch mode {
        case .off:
          device.torchMode = .off
        case .on:
          device.torchMode = .on
        }
        device.unlockForConfiguration()
      } catch {
        print(error.localizedDescription)
      }
    }
  }
}

// MARK: - Video / Audio Output Delegate

extension CaptureService: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from _: AVCaptureConnection
  ) {
    if let videoDataOutput = output as? AVCaptureVideoDataOutput {
      guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
      if videoDataOutput == videoOutput1 {
        streamingContinuation?.yield(.output1Frame(pixelBuffer))

        if let recorder = recorder1 {
          recorder.recordVideoSample(sampleBuffer: sampleBuffer)
          currentlyRecordedClipDuration = recorder.recordedDuration

          // Stop recording when limit is reached
          if let duration = recorder.recordedDuration,
             duration > remainingRecordingDuration {
            try? stopRecording()
          }
        }
      } else {
        streamingContinuation?.yield(.output2Frame(pixelBuffer))
        recorder2?.recordVideoSample(sampleBuffer: sampleBuffer)
      }
    } else {
      recorder1?.recordAudioSample(sampleBuffer: sampleBuffer)
    }
  }
}
