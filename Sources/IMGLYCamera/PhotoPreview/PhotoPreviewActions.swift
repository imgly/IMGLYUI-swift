@_spi(Internal) import IMGLYCore
import SwiftUI

/// Bottom action bar shown during `.previewingPhoto`: replaces the camera's flash/toggle/flip controls
/// with two text-label buttons — `Back` discards the JPEG, `Done` commits the capture.
struct PhotoPreviewActions: View {
  let onBack: () -> Void
  let onDone: () -> Void

  var body: some View {
    HStack {
      Button(action: onBack) {
        Text(.imgly.localized("ly_img_camera_button_photo_preview_back"))
      }
      .buttonStyle(PhotoPreviewButtonStyle(prominent: false))

      Spacer()

      Button(action: onDone) {
        Text(.imgly.localized("ly_img_camera_button_photo_preview_done"))
      }
      .buttonStyle(PhotoPreviewButtonStyle(prominent: true))
    }
  }
}

private struct PhotoPreviewButtonStyle: ButtonStyle {
  let prominent: Bool

  @ScaledMetric private var verticalPadding: Double = 9
  @ScaledMetric private var horizontalPadding: Double = 18

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.subheadline)
      .foregroundColor(.white)
      .padding(.vertical, verticalPadding)
      .padding(.horizontal, horizontalPadding)
      .background {
        Capsule().fill(background(isPressed: configuration.isPressed))
      }
      .contentShape(Capsule())
      .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
  }

  private func background(isPressed: Bool) -> AnyShapeStyle {
    if prominent {
      AnyShapeStyle(Color.accentColor.opacity(isPressed ? 0.8 : 1))
    } else {
      AnyShapeStyle(.regularMaterial.opacity(isPressed ? 0.8 : 1))
    }
  }
}
