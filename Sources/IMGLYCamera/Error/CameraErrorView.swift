import SwiftUI

/// Shown in place of the canvas when an error has occured.
struct CameraErrorView: View {
  let error: Error
  let retryCallback: () -> Void

  @ScaledMetric var iconSize: Double = 64

  var body: some View {
    VStack {
      if error as? CameraCaptureError == CameraCaptureError.permissionsMissing {
        // Permissions errors are handled in alerts, so we don’t show them here.
      } else {
        Image(systemName: "exclamationmark.triangle")
          .font(.system(size: iconSize))
          .fontWeight(.thin)
          .foregroundColor(.secondary)
          .padding(.bottom, iconSize / 3)

        Text(error.localizedDescription)
          .fontWeight(.medium)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.bottom, iconSize / 3 * 2)

        Button {
          retryCallback()
        } label: {
          Label {
            Text("Retry")
          } icon: {
            Image(systemName: "arrow.clockwise")
          }
        }
        .buttonStyle(BorderedButtonStyle())
        .controlSize(.large)
        .tint(.accentColor)
      }
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

struct CameraErrorView_Previews: PreviewProvider {
  static var previews: some View {
    CameraErrorView(error: CameraCaptureError.imglyEngineError("Test Error")) {
      print("Retry")
    }
    .environment(\.colorScheme, .dark)
  }
}
