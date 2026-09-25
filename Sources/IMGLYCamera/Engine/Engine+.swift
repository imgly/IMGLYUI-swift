import Foundation
import IMGLYEngine
@_spi(Internal) import IMGLYCoreUI
@_spi(Internal) import struct IMGLYCore.Error

public extension Engine {
  func createScene(from result: CameraResult) async throws {
    switch result {
    case let .reaction(video, reaction):
      try await createSceneFromReaction(video: video, recordings: reaction)

    case let .capture(captures):
      try await createSceneFromCaptures(captures)
    }
  }
}

private extension Engine {
  /// Creates a new scene and adds the given recordings to it.
  ///
  /// - Parameter recordings: The recordings to add.
  func createSceneFromRecordings(_ recordings: [Recording]) async throws {
    guard
      let firstRecording = recordings.first,
      let firstVideo = firstRecording.videos.first
    else { throw Error(errorDescription: "Tried creating a scene with an empty recording.") }

    // Create a scene with the first video on the background track
    try await createScene(with: firstVideo, frame: recordings.unionRect())
    guard let pageID = try scene.getCurrentPage() else {
      throw Error(errorDescription: "Failed to get current page.")
    }

    // Find the background track created in the scene.
    guard let backgroundTrack = try block.find(byType: .track).first else {
      throw Error(errorDescription: "Failed to get background track.")
    }

    try addCaptures(
      recordings.map(Capture.video),
      useBackgroundTrack: backgroundTrack,
      page: pageID,
      skipFirstVideoBecauseItWasAddedToTheSceneAlready: true,
    )
  }

  /// Adds a video and a reaction recording to the timeline.
  ///
  /// - Parameters:
  ///   - video: The video being reacted to.
  ///   - recordings: The recorded reaction, can be several clips.
  func createSceneFromReaction(video: Recording, recordings: [Recording]) async throws {
    guard let reactionVideo = video.videos.first else {
      throw Error(errorDescription: "Reaction recording missing video.")
    }

    // Create a scene with the video being reacted to.
    let sceneFrame = (recordings + [video]).unionRect()
    let (video, fill) = try await createScene(with: reactionVideo, frame: sceneFrame)
    guard let pageID = try scene.getCurrentPage() else {
      throw Error(errorDescription: "Failed to get current page.")
    }

    // Loop through the reaction recordings and add each clip to the timeline, offset by the previous clip's duration.
    let duration = try addCaptures(
      recordings.map(Capture.video),
      useBackgroundTrack: nil,
      page: pageID,
    )

    try await block.forceLoadAVResource(fill)

    // Finally set the duration of the video being reacted to to the total length of the reaction.
    try block.setTrimLength(fill, length: duration)
    try block.setTrimOffset(fill, offset: 0)
    try block.setDuration(video, duration: duration)
  }

  /// Creates a new scene from the given captures.
  ///
  /// - Parameter captures: The captures to render.
  func createSceneFromCaptures(_ captures: [Capture]) async throws {
    guard let first = captures.first else {
      throw Error(errorDescription: "Tried creating a scene with no captures.")
    }

    if captures.count == 1 {
      switch first {
      case let .photo(photo) where photo.images.count <= 1:
        guard let url = photo.images.first?.url else {
          throw Error(errorDescription: "Tried creating a scene from a photo capture with no images.")
        }
        _ = try await scene.create(fromImage: url)
        return
      case .photo:
        // Dual-camera photo: fall through to the multi-capture path so both images are laid out.
        break
      case let .video(recording):
        try await createSceneFromRecordings([recording])
        return
      }
    }

    try createEmptyTimelineScene()
    guard let pageID = try scene.getCurrentPage() else {
      throw Error(errorDescription: "Failed to get current page.")
    }
    guard let backgroundTrack = try block.find(byType: .track).first else {
      throw Error(errorDescription: "Failed to get background track.")
    }

    try addCaptures(captures, useBackgroundTrack: backgroundTrack, page: pageID)
  }

  /// Creates an empty timeline scene with a single page and a background track.
  func createEmptyTimelineScene() throws {
    let sceneBlock = try scene.createVideo()
    let page = try block.create(.page)
    try block.appendChild(to: sceneBlock, child: page)
    try block.setFrame(page, value: CGRect(origin: .zero, size: CameraConfiguration.defaultVideoSize))
    let track = try block.create(.track)
    try block.appendChild(to: page, child: track)
    try block.setAlwaysOnBottom(track, enabled: true)
    try block.fillParent(track)
    try block.setScopeEnabled(track, scope: .key(.editorSelect), enabled: false)
    if try block.supportsPageDurationSource(page, id: track) {
      try block.setPageDurationSource(page, id: track)
    }
  }

  /// Adds a still image to the current scene as a fixed-duration graphic block with image fill.
  func addImage(
    _ url: URL,
    frame: CGRect = CGRect(origin: .zero, size: CameraConfiguration.defaultVideoSize),
    duration: Double,
    at offset: Double,
    appendTo track: DesignBlockID,
  ) throws {
    try addClip(
      fillType: .image,
      fillURI: url,
      fillURIProperty: .fillImageImageFileURI,
      frame: frame,
      duration: duration,
      at: offset,
      appendTo: track,
    )
  }

  /// Creates a new scene from a video and sets it up.
  /// - Parameters:
  ///   - video: The video.
  ///   - frame: The frame of the scene.
  /// - Returns: A tuple containing the block IDs for the video and its fill.
  @discardableResult
  func createScene(
    with video: Recording.Video,
    frame: CGRect,
  ) async throws -> (video: DesignBlockID, videoFill: DesignBlockID) {
    // Create a scene with the video being reacted to.
    try await scene.create(fromVideo: video.url)
    if let page = try scene.getCurrentPage() {
      try block.setFrame(page, value: frame)
    }

    guard let videoBlock = try block.find(byType: .graphic).first else {
      throw Error(errorDescription: "Failed to find the video block.")
    }
    let fill = try block.getFill(videoBlock)
    try block.setFrame(videoBlock, value: video.rect)
    return (videoBlock, fill)
  }

  /// Adds an array of `Capture`s to the scene.
  ///
  /// - Parameters:
  ///   - captures: The captures to add.
  ///   - backgroundTrack: The ID of the background track if that should be used. When defined the first video of each
  ///   recording (and any photo) is added to the background track.
  ///   - page: The current page.
  ///   - skipFirstVideoBecauseItWasAddedToTheSceneAlready: Setting this to `true` skips the first video of the first
  ///   recording, since `createSceneFromRecordings` seeds the scene from that video. Only applies to video captures —
  ///   photos must not be passed as the first capture when this flag is set.
  /// - Returns: The total duration of all captures.
  @discardableResult
  func addCaptures(
    _ captures: [Capture],
    useBackgroundTrack backgroundTrack: DesignBlockID?,
    page: DesignBlockID,
    skipFirstVideoBecauseItWasAddedToTheSceneAlready: Bool = false,
  ) throws -> Double {
    var didSkipFirstVideo = false
    var offset: Double = 0
    var trackForVideoIndex: [Int: DesignBlockID] = [:]
    if let backgroundTrack {
      trackForVideoIndex[0] = backgroundTrack
    }

    for capture in captures {
      let captureDuration = capture.duration.seconds
      switch capture {
      case let .photo(photo):
        assert(
          !(skipFirstVideoBecauseItWasAddedToTheSceneAlready && !didSkipFirstVideo),
          "skipFirstVideo… is video-only; the seed capture must be a video.",
        )
        for (index, image) in photo.images.enumerated() {
          let parent: DesignBlockID
          if let existing = trackForVideoIndex[index] {
            parent = existing
          } else {
            let newTrack = try block.create(.track)
            try block.appendChild(to: page, child: newTrack)
            trackForVideoIndex[index] = newTrack
            parent = newTrack
          }
          // For single-camera photos the rect is the full page; for dual it's the sub-rect.
          let frame = photo.images.count > 1
            ? image.rect
            : CGRect(origin: .zero, size: CameraConfiguration.defaultVideoSize)
          try addImage(image.url, frame: frame, duration: captureDuration, at: offset, appendTo: parent)
        }
      case let .video(recording):
        for (index, video) in recording.videos.enumerated() {
          if skipFirstVideoBecauseItWasAddedToTheSceneAlready, !didSkipFirstVideo {
            didSkipFirstVideo = true
            continue
          }
          let parent: DesignBlockID
          if let existing = trackForVideoIndex[index] {
            parent = existing
          } else {
            let newTrack = try block.create(.track)
            try block.appendChild(to: page, child: newTrack)
            trackForVideoIndex[index] = newTrack
            parent = newTrack
          }
          try addVideo(video, duration: captureDuration, at: offset, appendTo: parent)
        }
      }
      offset += captureDuration
    }
    return offset
  }

  /// Adds a video to the current scene.
  ///
  /// - Parameters:
  ///   - video: The video to add.
  ///   - duration: The duration the clip should occupy on the timeline.
  ///   - offset: Where to put the video on the timeline.
  ///   - track: The track to add the clip to.
  func addVideo(
    _ video: Recording.Video,
    duration: Double,
    at offset: Double,
    appendTo track: DesignBlockID,
  ) throws {
    try addClip(
      fillType: .video,
      fillURI: video.url,
      fillURIProperty: .fillVideoFileURI,
      frame: video.rect,
      duration: duration,
      at: offset,
      appendTo: track,
    )
  }

  /// Adds a fixed-duration graphic block with the given fill to the current scene.
  func addClip(
    fillType: FillType,
    fillURI: URL,
    fillURIProperty: PropertyKey,
    frame: CGRect,
    duration: Double,
    at offset: Double,
    appendTo track: DesignBlockID,
  ) throws {
    let id = try block.create(.graphic)
    let rectShape = try block.createShape(.rect)
    try block.setShape(id, shape: rectShape)
    try block.appendChild(to: track, child: id)
    try block.setFrame(id, value: frame)
    try block.setTimeOffset(id, offset: offset)
    let fill = try block.createFill(fillType)
    try block.set(fill, property: .key(fillURIProperty), value: fillURI)
    try block.setFill(id, fill: fill)
    try block.setDuration(id, duration: duration)
  }
}

// MARK: - Helpers

private extension [Recording] {
  /// Returns: A `CGRect` containing all of the video's in the array of recordings.
  func unionRect() -> CGRect {
    flatMap(\.videos).reduce(.zero) { partialResult, next in
      partialResult.union(next.rect)
    }
  }
}
