import UIKit
@_spi(Fork) import IMGLYCamera
@_spi(Internal) import IMGLYCamera

public extension OnCreate {
    /// Creates a callback that loads the output of the camera as scene and the default and demo asset sources.
    /// - Parameter result: The camera result to load a scene with.
    /// - Returns: The callback.
    static func loadVideos(from result: CameraResult) -> Callback {
        { engine in
            try await engine.createScene(from: result)
            try await loadAssetSources(engine)
        }
    }
}

@_spi(Fork) public extension OnCreate {
    /// Creates a callback that loads the camera output as a scene and then loads the default and demo asset sources.
    /// - Parameters:
    ///   - result: The `CameraResult` produced by the camera that should be used to create the scene.
    ///   - size: An optional target `CGSize` to which the created scene should be constrained. Pass `nil` to use the source dimensions.
    ///   - maxTrimmingDuration: An optional maximum duration, in seconds, used to trim the loaded video(s). Pass `nil` to keep the full duration.
    /// - Returns: A `Callback` that, when executed with an engine, creates a scene from the provided camera result (respecting the optional size and trimming limit) and loads the default and demo asset sources.
    /// - Note: This variant is available via the Fork SPI and extends the basic loader with optional sizing and trimming controls.
    static func loadVideos(
        from result: CameraResult,
        size: CGSize? = nil,
        maxTrimmingDuration: Double? = nil
    ) -> Callback {
        Task { @MainActor in OnCreate.sceneCreatingTracker = .inProgress }

        return { engine in
            try await engine.createScene(from: result, size: size, maxTrimmingDuration: maxTrimmingDuration)
            try await loadAssetSources(engine)

            Task { @MainActor in OnCreate.sceneCreatingTracker = .created }
        }
    }
}
