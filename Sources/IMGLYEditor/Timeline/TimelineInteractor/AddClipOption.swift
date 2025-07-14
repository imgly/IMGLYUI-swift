import Foundation
import SwiftUI

/// Options for adding clips to the timeline
@_spi(Internal) public enum AddClipOption: CaseIterable {
  case gallery
  case camera
  case library

  /// The default configuration for the timeline add clip buttons
  @_spi(Internal) public static var defaultOptions: [AddClipOption] = [.camera, .gallery, .library]

  /// Display name for the option
  public var displayName: LocalizedStringResource {
    switch self {
    case .gallery:
      .imgly.localized("ly_img_editor_timeline_add_clip_option_photo_roll")
    case .camera:
      .imgly.localized("ly_img_editor_timeline_add_clip_option_camera")
    case .library:
      .imgly.localized("ly_img_editor_timeline_add_clip_option_library")
    }
  }

  /// Icon name for the option (SF Symbols)
  public var iconName: String {
    switch self {
    case .gallery:
      "custom.photo.fill.on.rectangle.fill.badge.plus"
    case .camera:
      "custom.camera.fill.badge.plus"
    case .library:
      "play.square.stack"
    }
  }

  /// Set custom options
  @_spi(Internal) @MainActor public static func setOptions(_ options: [AddClipOption]) {
    defaultOptions = options
  }
}
