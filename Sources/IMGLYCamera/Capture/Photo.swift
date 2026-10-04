import CoreMedia
import Foundation

/// A camera photo capture.
public struct Photo: Equatable, Sendable {
  /// A single still image inside a photo capture.
  public struct Image: Equatable, Sendable {
    /// The URL of the photo file.
    public let url: URL
    /// The position and size of the image within the upright capture canvas. In single-camera
    /// mode this is the full canvas; in dual-camera mode it is the top/bottom or left/right half.
    /// Landscape captures use a 1920x1080 canvas; portrait captures use 1080x1920.
    public let rect: CGRect
  }

  /// Contains one `Image` in single-camera mode or two `Image`s stacked per `cameraMode.layoutMode`
  /// in dual-camera mode.
  public let images: [Image]

  /// The duration stamped on the photo.
  public let duration: CMTime
}
