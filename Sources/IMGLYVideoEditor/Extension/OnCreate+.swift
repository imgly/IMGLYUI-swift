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
