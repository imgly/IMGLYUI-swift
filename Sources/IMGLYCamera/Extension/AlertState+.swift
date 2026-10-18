import UIKit
@_spi(Internal) import IMGLYCoreUI

extension AlertState {
  static func cameraPermissions(cancel: @escaping @MainActor () -> Void) -> Self {
    AlertState(
      title: CamMicUsageDescriptionFromBundleHelper.cameraAlertHeadline,
      message: String(localized: CamMicUsageDescriptionFromBundleHelper.cameraUsageDescription),
      buttons: [
        .init(
          title: .imgly.localized("ly_img_editor_dialog_permission_camera_button_dismiss", table: .imglyCoreUI),
          role: .cancel,
          action: cancel,
        ),
        .init(title: .imgly.localized("ly_img_editor_dialog_permission_camera_button_confirm", table: .imglyCoreUI)) {
          cancel()
          if let url = URL(string: UIApplication.openSettingsURLString) {
            Task {
              await UIApplication.shared.open(url)
            }
          }
        },
      ],
    )
  }

  static func microphonePermissions(cancel: @escaping @MainActor () -> Void) -> Self {
    AlertState(
      title: CamMicUsageDescriptionFromBundleHelper.microphoneAlertHeadline,
      message: String(localized: CamMicUsageDescriptionFromBundleHelper.microphoneUsageDescription),
      buttons: [
        .init(
          title: .imgly.localized("ly_img_editor_dialog_permission_microphone_button_dismiss", table: .imglyCoreUI),
          role: .cancel,
          action: cancel,
        ),
        .init(
          title: .imgly.localized("ly_img_editor_dialog_permission_microphone_button_confirm", table: .imglyCoreUI),
        ) {
          cancel()
          if let url = URL(string: UIApplication.openSettingsURLString) {
            Task {
              await UIApplication.shared.open(url)
            }
          }
        },
      ],
    )
  }

  static func failedToLoadVideo(cancel: @escaping @MainActor () -> Void) -> Self {
    AlertState(title: .imgly.localized("ly_img_camera_dialog_video_error_title"), buttons: [
      .init(
        title: .imgly.localized("ly_img_camera_dialog_video_error_button_dismiss"),
        action: cancel,
      ),
    ])
  }
}
