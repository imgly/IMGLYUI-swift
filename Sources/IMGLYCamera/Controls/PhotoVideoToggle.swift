@_spi(Internal) import IMGLYCore
import IMGLYCoreUI
import SwiftUI

/// Segmented control that flips `CameraModel.activeMixedSubMode` while `captureType == .mixed`.
struct PhotoVideoToggle: View {
  @EnvironmentObject var camera: CameraModel

  var body: some View {
    Picker("", selection: $camera.activeMixedSubMode) {
      Image(systemName: camera.activeMixedSubMode == .photo ? "camera.fill" : "camera")
        .accessibilityLabel(Text(.imgly.localized("ly_img_camera_button_photo_mode")))
        .tag(ActiveMixedSubMode.photo)
      Image(systemName: camera.activeMixedSubMode == .video ? "film.fill" : "film")
        .accessibilityLabel(Text(.imgly.localized("ly_img_camera_button_video_mode")))
        .tag(ActiveMixedSubMode.video)
    }
    .pickerStyle(.segmented)
    .controlSize(.large)
    .frame(width: 96)
    .onChange(of: camera.activeMixedSubMode) { _ in
      HapticsHelper.shared.cameraSelectFeature()
    }
  }
}
