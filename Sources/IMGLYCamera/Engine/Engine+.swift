import UIKit
import Foundation
import IMGLYEngine
@_spi(Internal) import IMGLYCoreUI
@_spi(Internal) import struct IMGLYCore.Error

@_spi(Internal) public extension Engine {
    func createScene(from result: CameraResult) async throws {
        switch result {
        case let .recording(recordings):
            try await createSceneFromRecordings(recordings)

        case let .reaction(video, reaction):
            try await createSceneFromReaction(video: video, recordings: reaction)
        }
    }
}

@_spi(Fork) public extension Engine {
    func createScene(
        from result: CameraResult,
        size: CGSize? = nil,
        maxTrimmingDuration: Double? = nil
    ) async throws {
        switch result {
        case let .recording(recordings):
            try await createSceneFromRecordings(
                recordings,
                size: size,
                maxTrimmingDuration: maxTrimmingDuration
            )

        case let .reaction(video, reaction):
            try await createSceneFromReaction(video: video, recordings: reaction)
        }
    }
}

private extension Engine {
    /// Creates a new scene and adds the given recordings to it.
    ///
    /// - Parameter recordings: The recordings to add.
    func createSceneFromRecordings(
        _ recordings: [Recording],
        size: CGSize? = nil,
        maxTrimmingDuration: Double? = nil
    ) async throws {
        guard let firstRecording = recordings.first, let firstVideo = firstRecording.videos.first else {
            throw Error(errorDescription: "Tried creating a scene with an empty recording.")
        }

        var rect = recordings.unionRect()
        if let size {
            rect = .init(origin: .zero, size: size)
        }

        var duration = firstRecording.duration.seconds
        if let maxTrimmingDuration {
            duration = min(maxTrimmingDuration, duration)
        }

        // Create a scene with the first video on the background track
        try await createScene(with: firstVideo, frame: rect, duration: duration)
        guard let pageID = try scene.getCurrentPage() else {
            throw Error(errorDescription: "Failed to get current page.")
        }

        // Find the background track created in the scene.
        guard let backgroundTrack = try block.find(byType: .track).first else {
            throw Error(errorDescription: "Failed to get background track.")
        }

        try addRecordings(
            recordings,
            useBackgroundTrack: backgroundTrack,
            page: pageID,
            skipFirstVideoBecauseItWasAddedToTheSceneAlready: true,
            maxTrimmingDuration: maxTrimmingDuration
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
        let (video, fill) = try await createScene(
            with: reactionVideo,
            frame: sceneFrame,
            duration: video.duration.seconds
        )

        guard let pageID = try scene.getCurrentPage() else {
            throw Error(errorDescription: "Failed to get current page.")
        }

        // Loop through the reaction recordings and add each clip to the timeline, offset by the previous clip's duration.
        let duration = try addRecordings(
            recordings,
            useBackgroundTrack: nil,
            page: pageID,
        )

        try await block.forceLoadAVResource(fill)

        // Finally set the duration of the video being reacted to to the total length of the reaction.
        try block.setTrimLength(fill, length: duration)
        try block.setTrimOffset(fill, offset: 0)
        try block.setDuration(video, duration: duration)
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
        duration: Double
    ) async throws -> (video: DesignBlockID, videoFill: DesignBlockID) {
        // Create a scene with the video being reacted to.
        try await scene.create(fromVideo: video.url)

        if let page = try scene.getCurrentPage() {
            try block.setFrame(page, value: frame)
        }

        guard let videoBlock = try block.find(byType: .graphic).first else {
            throw Error(errorDescription: "Failed to find the video block.")
        }

        let fillBlock = try block.getFill(videoBlock)
        try block.setFrame(videoBlock, value: video.rect)

        if
            let isTrimSupported = try? block.supportsTrim(fillBlock), isTrimSupported,
            let isDurationSupported = try? block.supportsDuration(videoBlock), isDurationSupported
        {
            try block.setTrimLength(fillBlock, length: duration)
            try block.setDuration(videoBlock, duration: duration)
        }

        return (videoBlock, fillBlock)
    }

    /// Adds an array of `Recording`s to the scene.
    ///
    /// - Parameters:
    ///   - recordings: The recordings to add.
    ///   - engine: The engine holding the scene that the recordings should be added to.
    ///   - backgroundTrack: The ID of the background track if that should be used. When defined the first video of each
    ///   recording is added to the background track.
    ///   - page: The current page.
    ///   - skipFirstVideoBecauseItWasAddedToTheSceneAlready: Setting this to `true` skips the first video of the first
    ///   recording as this is often used to create the scene.
    /// - Returns: The total duration of all recordings.
    @discardableResult
    func addRecordings(
        _ recordings: [Recording],
        useBackgroundTrack backgroundTrack: DesignBlockID?,
        page: DesignBlockID,
        skipFirstVideoBecauseItWasAddedToTheSceneAlready: Bool = false,
        maxTrimmingDuration: Double? = nil
    ) throws -> Double {
        var didSkipFirstVideo = false
        var offset: Double = 0
        var maxTrimmingDuration = maxTrimmingDuration

        for recording in recordings {
            var duration = recording.duration.seconds
            if let maxTrimmingDuration {
                duration = min(maxTrimmingDuration, duration)
            }

            for (index, video) in recording.videos.enumerated() {
                if skipFirstVideoBecauseItWasAddedToTheSceneAlready, !didSkipFirstVideo {
                    didSkipFirstVideo = true
                    continue
                }

                let track = index == 0 ? (backgroundTrack ?? page) : page
                try addVideo(
                    video,
                    duration: duration,
                    at: offset,
                    appendTo: track,
                )
            }

            offset += duration
            if let maxDuration = maxTrimmingDuration {
                maxTrimmingDuration = maxDuration - duration
            }
        }

        return offset
    }

    /// Adds a video to the current scene.
    ///
    /// - Parameters:
    ///   - video: The video to add.
    ///   - engine: The engine to add the video to.
    ///   - offset: Where to put the video on the timeline.
    ///   - track: The track to add the clip to.
    func addVideo(
        _ video: Recording.Video,
        duration: Double,
        at offset: Double,
        appendTo track: DesignBlockID,
    ) throws {
        let rect = video.rect
        let rootBlock = try block.create(.graphic)
        let rectShapeBlock = try block.createShape(.rect)

        try block.setShape(rootBlock, shape: rectShapeBlock)
        try block.appendChild(to: track, child: rootBlock)
        try block.setFrame(rootBlock, value: rect)
        try block.setTimeOffset(rootBlock, offset: offset)

        let fillBlock = try block.createFill(.video)

        try block.set(fillBlock, property: .key(.fillVideoFileURI), value: video.url)
        try block.setFill(rootBlock, fill: fillBlock)

        if
            let isTrimSupported = try? block.supportsTrim(fillBlock), isTrimSupported,
            let isDurationSupported = try? block.supportsDuration(rootBlock), isDurationSupported
        {
            try block.setTrimLength(fillBlock, length: duration)
            try block.setDuration(rootBlock, duration: duration)
        }
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
