import UIKit
@_spi(Internal) import IMGLYCoreUI

extension AlertState {
  static func cameraPermissions(cancel: @escaping () -> Void) -> Self {
    AlertState(
      title: CamMicUsageDescriptionFromBundleHelper.shared.cameraAlertHeadline,
      message: CamMicUsageDescriptionFromBundleHelper.shared.cameraUsageDescription,
      buttons: [
        .init(title: "Don't Allow", role: .cancel, action: cancel),
        .init(title: "Settings") {
          cancel()
          if let url = URL(string: UIApplication.openSettingsURLString) {
            Task {
              await UIApplication.shared.open(url)
            }
          }
        },
      ]
    )
  }

  static func microphonePermissions(cancel: @escaping () -> Void) -> Self {
    AlertState(
      title: CamMicUsageDescriptionFromBundleHelper.shared.microphoneAlertHeadline,
      message: CamMicUsageDescriptionFromBundleHelper.shared.microphoneUsageDescription,
      buttons: [
        .init(title: "Don't Allow", role: .cancel, action: cancel),
        .init(title: "Settings") {
          cancel()
          if let url = URL(string: UIApplication.openSettingsURLString) {
            Task {
              await UIApplication.shared.open(url)
            }
          }
        },
      ]
    )
  }
}
