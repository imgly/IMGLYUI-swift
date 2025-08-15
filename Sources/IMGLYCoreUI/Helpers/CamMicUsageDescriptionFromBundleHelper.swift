import Foundation

/// These strings are used in custom alerts that are shown after the user has initially denied access.
@_spi(Internal) public class CamMicUsageDescriptionFromBundleHelper {
  @_spi(Internal) public static let shared = CamMicUsageDescriptionFromBundleHelper()

  @_spi(Internal) public var cameraAlertHeadline: LocalizedStringResource {
    .imgly.localized("ly_img_editor_dialog_permission_camera_title")
  }

  @_spi(Internal) public var microphoneAlertHeadline: LocalizedStringResource {
    .imgly.localized("ly_img_editor_dialog_permission_microphone_title")
  }

  @_spi(Internal) public var cameraUsageDescription: LocalizedStringResource {
    .imgly.localized("ly_img_editor_dialog_permission_camera_text")
  }

  @_spi(Internal) public var microphoneUsageDescription: LocalizedStringResource {
    .imgly.localized("ly_img_editor_dialog_permission_microphone_text")
  }
}
