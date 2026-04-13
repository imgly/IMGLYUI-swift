@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEditor
import SwiftUI

extension PreviewProvider {
  @ViewBuilder static var designEditor: some View {
    NavigationView {
      getSecrets { secrets in
        DesignEditor(.init(license: secrets.licenseKey, userID: "swiftui-preview-user"))
      }
    }
  }

  @ViewBuilder static var defaultPreviews: some View {
    Group {
      designEditor
      designEditor.imgly.nonDefaultPreviewSettings()
    }
    .navigationViewStyle(.stack)
  }
}
