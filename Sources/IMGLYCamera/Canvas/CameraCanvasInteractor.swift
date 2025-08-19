@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEngine
import SwiftUI

/// Manages the IMGLYEngine that displays the camera images.
@MainActor
class CameraCanvasInteractor: ObservableObject {
  var engine: Engine?

  private var scene: DesignBlockID
  private var page: DesignBlockID

  private var streamRect1: DesignBlockID
  private var pixelStreamFill1: DesignBlockID

  private var streamRect2: DesignBlockID
  private var pixelStreamFill2: DesignBlockID

  private var backgroundRect: DesignBlockID

  private var reactionVideo: ReactionVideo?

  let canvasWidth: Float
  let canvasHeight: Float

  private var currentCameraLayout: (CGRect, CGRect?) = (.zero, nil)

  init(settings: EngineSettings, videoSize: CGSize) async throws {
    let engine = try await Engine(license: settings.license, userID: settings.userID)
    try engine.editor.setSettingString("basePath", value: settings.baseURL.absoluteString)
    self.engine = engine

    canvasWidth = Float(videoSize.width)
    canvasHeight = Float(videoSize.height)

    scene = try engine.scene.createVideo()

    try engine.editor.setGlobalScope(key: ScopeKey.editorSelect.rawValue, value: .deny)
    try engine.editor.setSettingBool("touch/singlePointPanning", value: false)
    try engine.editor.setSettingFloat("positionSnappingThreshold", value: 8.0)

    // Set up the page
    page = try engine.block.create(.page)
    try engine.block.appendChild(to: scene, child: page)

    try engine.block.setWidth(scene, value: canvasWidth)
    try engine.block.setHeight(scene, value: canvasHeight)

    try engine.block.setWidth(page, value: canvasWidth)
    try engine.block.setHeight(page, value: canvasHeight)

    // Set up the black background
    backgroundRect = try engine.block.create(.graphic)
    let backgroundShape = try engine.block.createShape(.rect)
    try engine.block.setShape(backgroundRect, shape: backgroundShape)
    let backgroundFill = try engine.block.createFill(.color)
    try engine.block.set(backgroundFill, property: .key(.fillColorValue), value: Color.rgba(r: 0, g: 0, b: 0, a: 1))

    try engine.block.setFill(backgroundRect, fill: backgroundFill)
    try engine.block.setWidth(backgroundRect, value: canvasWidth)
    try engine.block.setHeight(backgroundRect, value: canvasHeight)
    try engine.block.setPositionX(backgroundRect, value: 0)
    try engine.block.setPositionY(backgroundRect, value: 0)

    try engine.block.appendChild(to: page, child: backgroundRect)

    // Set up the primary stream
    streamRect1 = try engine.block.create(.graphic)
    let shape1 = try engine.block.createShape(.rect)
    try engine.block.setShape(streamRect1, shape: shape1)
    try engine.block.setVisible(streamRect1, visible: true)

    try engine.block.setWidth(streamRect1, value: canvasWidth)
    try engine.block.setHeight(streamRect1, value: canvasHeight)
    try engine.block.setPositionX(streamRect1, value: 0)
    try engine.block.setPositionY(streamRect1, value: 0)

    try engine.block.appendChild(to: page, child: streamRect1)

    pixelStreamFill1 = try engine.block.createFill(.pixelStream)
    try engine.block.setFill(streamRect1, fill: pixelStreamFill1)

    // Set up the secondary stream
    streamRect2 = try engine.block.create(.graphic)
    let shape2 = try engine.block.createShape(.rect)
    try engine.block.setShape(streamRect2, shape: shape2)
    try engine.block.appendChild(to: page, child: streamRect2)

    try engine.block.setWidth(streamRect2, value: canvasWidth)
    try engine.block.setHeight(streamRect2, value: canvasHeight)
    try engine.block.setPositionX(streamRect2, value: 0)
    try engine.block.setPositionY(streamRect2, value: 0)

    try engine.block.setVisible(streamRect2, visible: false)

    pixelStreamFill2 = try engine.block.createFill(.pixelStream)
    try engine.block.setFill(streamRect2, fill: pixelStreamFill2)

    try purgeBuffers()

    Task {
      try await engine.scene.zoom(to: page)
      try engine.scene.enableZoomAutoFit(
        scene,
        axis: .both,
        paddingLeft: 0,
        paddingTop: 0,
        paddingRight: 0,
        paddingBottom: 0,
      )
    }
  }

  func updatePixelStreamFill1(buffer: CVImageBuffer) throws {
    guard let engine else { throw Error(errorDescription: "Engine missing.") }
    try engine.block.setNativePixelBuffer(pixelStreamFill1, buffer: buffer)
  }

  func updatePixelStreamFill2(buffer: CVImageBuffer) throws {
    guard let engine else { throw Error(errorDescription: "Engine missing.") }
    try engine.block.setNativePixelBuffer(pixelStreamFill2, buffer: buffer)
  }

  func setCameraLayout(_ rect1: CGRect, _ rect2: CGRect? = nil) throws {
    guard let engine else { throw Error(errorDescription: "Engine missing.") }
    guard currentCameraLayout.0 != rect1 || currentCameraLayout.1 != rect2 else { return }
    currentCameraLayout = (rect1, rect2)

    switch (rect2, reactionVideo) {
    case let (.some(rect2), .none):
      try engine.block.setFrame(streamRect1, value: rect1)
      try engine.block.setVisible(streamRect2, visible: true)
      try engine.block.setFrame(streamRect2, value: rect2)

    case let (.some(rect2), .some(reactionVideo)):
      try engine.block.setFrame(streamRect1, value: rect2)
      try engine.block.setFrame(reactionVideo.graphic, value: rect1)

    default:
      try engine.block.setFrame(streamRect1, value: rect1)
      try engine.block.setVisible(streamRect2, visible: false)
    }
  }

  func loadVideo(url: URL) async throws -> ReactionVideo {
    guard let engine else { throw Error(errorDescription: "Engine missing.") }
    if let video = reactionVideo, video.url == url {
      return video
    } else {
      let frame = currentCameraLayout.0
      let video = try await engine.addVideo(
        url: url,
        frame: frame,
        page: page,
      )
      try engine.block.setFrame(streamRect1, value: currentCameraLayout.1 ?? .zero)
      reactionVideo = video
      return video
    }
  }

  func clearVideo() throws {
    guard let reactionVideo else { return }
    guard let engine else { throw Error(errorDescription: "Engine missing.") }
    try engine.block.destroy(reactionVideo.fill)
    try engine.block.destroy(reactionVideo.graphic)
  }

  var reactionVideoDuration: Double? {
    guard let engine, let reactionVideo else { return nil }
    return try? engine.block.getAVResourceTotalDuration(reactionVideo.fill)
  }

  func reactionVideoSetPlaying(_ playing: Bool) {
    guard let engine, let reactionVideo else { return }
    try? engine.block.setPlaying(reactionVideo.fill, enabled: playing)
  }

  func setReactionPlaybackTime(_ time: Double) throws {
    guard let engine, let reactionVideo else { return }
    try engine.block.setPlaybackTime(reactionVideo.fill, time: time)
  }

  /// Clear both camera image buffers by filling them with a transparent pixel.
  func purgeBuffers() throws {
    guard let engine else { throw Error(errorDescription: "Engine missing.") }
    var pixelBuffer: CVPixelBuffer?

    CVPixelBufferCreate(kCFAllocatorDefault, 1, 1, kCVPixelFormatType_32BGRA, nil, &pixelBuffer)
    guard let pixelBuffer else { throw Error(errorDescription: "Could not create pixel buffer.") }
    try engine.block.setNativePixelBuffer(pixelStreamFill1, buffer: pixelBuffer)
    try engine.block.setNativePixelBuffer(pixelStreamFill2, buffer: pixelBuffer)
  }

  func destroyEngine() {
    engine = nil
  }
}

struct ReactionVideo {
  var graphic: DesignBlockID
  var fill: DesignBlockID
  var url: URL
  var duration: Double
}

extension Engine {
  func addVideo(
    url: URL,
    frame: CGRect,
    page: DesignBlockID,
  ) async throws -> ReactionVideo {
    let video = try block.create(.graphic)
    try block.setShape(video, shape: block.createShape(.rect))
    let videoFill = try block.createFill(.video)
    try block.set(videoFill, property: .key(.fillVideoFileURI), value: url)
    try block.setFill(video, fill: videoFill)
    try block.setFrame(video, value: frame)
    try block.setSoloPlaybackEnabled(videoFill, enabled: true)
    try block.appendChild(to: page, child: video)
    try await block.forceLoadAVResource(videoFill)
    let duration = try block.getAVResourceTotalDuration(videoFill)
    try block.setDuration(video, duration: duration)
    return ReactionVideo(graphic: video, fill: videoFill, url: url, duration: duration)
  }
}
