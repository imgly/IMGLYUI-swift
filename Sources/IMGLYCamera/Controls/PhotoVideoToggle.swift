@_spi(Internal) import IMGLYCore
import IMGLYCoreUI
import SwiftUI

/// Segmented control that flips `CameraModel.activeMixedSubMode` while `captureType == .mixed`.
struct PhotoVideoToggle: View {
  @EnvironmentObject var camera: CameraModel
  @Namespace private var selection

  var body: some View {
    HStack(spacing: 0) {
      segment(.photo, symbol: camera.activeMixedSubMode == .photo ? "camera.fill" : "camera",
              label: .imgly.localized("ly_img_camera_button_photo_mode"))
      segment(.video, symbol: camera.activeMixedSubMode == .video ? "film.fill" : "film",
              label: .imgly.localized("ly_img_camera_button_video_mode"))
    }
    .padding(2)
    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    .frame(width: 96)
    .animation(.easeInOut(duration: 0.2), value: camera.activeMixedSubMode)
    .onChange(of: camera.activeMixedSubMode) { _ in
      HapticsHelper.shared.cameraSelectFeature()
    }
  }

  private func segment(_ mode: ActiveMixedSubMode, symbol: String, label: LocalizedStringResource) -> some View {
    Button { camera.activeMixedSubMode = mode } label: {
      Image(systemName: symbol)
        .cameraRotationEffect()
        .frame(maxWidth: .infinity, minHeight: 32)
        .background {
          if camera.activeMixedSubMode == mode {
            RoundedRectangle(cornerRadius: 6).fill(.regularMaterial)
              .matchedGeometryEffect(id: "selection", in: selection)
          }
        }
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(Text(label))
    .accessibilityAddTraits(camera.activeMixedSubMode == mode ? [.isSelected] : [])
  }
}
