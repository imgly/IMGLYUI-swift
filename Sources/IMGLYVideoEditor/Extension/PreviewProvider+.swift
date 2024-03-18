@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEditor
import SwiftUI

extension PreviewProvider {
  @ViewBuilder static var videoEditor: some View {
    NavigationView {
      getSecrets { secrets in
        VideoEditor(.init(license: secrets.licenseKey, userID: "swiftui-preview-user"))
      }
    }
  }

  @ViewBuilder static var defaultPreviews: some View {
    Group {
      videoEditor
      videoEditor.imgly.nonDefaultPreviewSettings()
    }
    .navigationViewStyle(.stack)
  }
}
