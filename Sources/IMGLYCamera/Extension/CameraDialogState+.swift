import UIKit
@_spi(Internal) import IMGLYCoreUI

extension CameraDialogState {
  static func cameraPermissions(cancel: @escaping @MainActor () -> Void) -> Self {
    CameraDialogState(
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
    CameraDialogState(
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
    CameraDialogState(title: .imgly.localized("ly_img_camera_dialog_video_error_title"), buttons: [
      .init(
        title: .imgly.localized("ly_img_camera_dialog_video_error_button_dismiss"),
        action: cancel,
      ),
    ])
  }

  static func deleteAll(confirm: @escaping @MainActor () -> Void) -> Self {
    CameraDialogState(
      title: .imgly.localized("ly_img_camera_dialog_delete_recordings_title"),
      message: String(localized: .imgly.localized("ly_img_camera_dialog_delete_recordings_text")),
      buttons: [
        .init(title: .imgly.localized("ly_img_camera_dialog_delete_recordings_button_confirm"),
              role: .destructive, action: confirm),
        .init(title: .imgly.localized("ly_img_camera_dialog_delete_recordings_button_dismiss"),
              role: .cancel, action: {}),
      ],
    )
  }

  static func deleteLast(confirm: @escaping @MainActor () -> Void) -> Self {
    CameraDialogState(
      title: .imgly.localized("ly_img_camera_dialog_delete_last_recording_title"),
      message: String(localized: .imgly.localized("ly_img_camera_dialog_delete_last_recording_text")),
      buttons: [
        .init(title: .imgly.localized("ly_img_camera_dialog_delete_last_recording_button_confirm"),
              role: .destructive, action: confirm),
        .init(title: .imgly.localized("ly_img_camera_dialog_delete_last_recording_button_dismiss"),
              role: .cancel, action: {}),
      ],
    )
  }
}
