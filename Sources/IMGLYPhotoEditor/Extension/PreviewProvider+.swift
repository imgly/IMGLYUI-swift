@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEditor
import SwiftUI

extension PreviewProvider {
  @ViewBuilder static var photoEditor: some View {
    NavigationView {
      getSecrets { secrets in
        PhotoEditor(.init(license: secrets.licenseKey, userID: "swiftui-preview-user"))
      }
    }
  }

  @ViewBuilder static var defaultPreviews: some View {
    Group {
      photoEditor
      photoEditor.imgly.nonDefaultPreviewSettings()
    }
    .navigationViewStyle(.stack)
  }
}
