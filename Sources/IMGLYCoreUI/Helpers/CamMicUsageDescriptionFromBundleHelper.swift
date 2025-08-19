import Foundation

/// These strings are used in custom alerts that are shown after the user has initially denied access.
@_spi(Internal) public class CamMicUsageDescriptionFromBundleHelper {
  @_spi(Internal) public static var cameraAlertHeadline: LocalizedStringResource {
    .imgly.localized("ly_img_editor_dialog_permission_camera_title")
  }

  @_spi(Internal) public static var microphoneAlertHeadline: LocalizedStringResource {
    .imgly.localized("ly_img_editor_dialog_permission_microphone_title")
  }

  @_spi(Internal) public static var cameraUsageDescription: LocalizedStringResource {
    .imgly.localized("ly_img_editor_dialog_permission_camera_text")
  }

  @_spi(Internal) public static var microphoneUsageDescription: LocalizedStringResource {
    .imgly.localized("ly_img_editor_dialog_permission_microphone_text")
  }
}
