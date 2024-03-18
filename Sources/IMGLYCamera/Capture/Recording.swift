import CoreMedia
import Foundation

public struct Recording: Equatable {
  public struct Video: Equatable {
    public let url: URL
    public let rect: CGRect
  }

  /// Contains one or two `Video`s, for single camera mode and dual camera mode respectively.
  public let videos: [Video]
  public let duration: CMTime
}
