@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEditor
import SwiftUI

extension PreviewProvider {
  private static var url: URL {
    getResource("thank_you", withExtension: "scene")
  }

  @ViewBuilder static var postcardEditor: some View {
    NavigationView {
      getSecrets { secrets in
        PostcardEditor(.init(license: secrets.licenseKey, userID: "swiftui-preview-user"))
          .imgly.onCreate(OnCreate.loadScene(from: url))
      }
    }
  }

  @ViewBuilder static var defaultPreviews: some View {
    Group {
      postcardEditor
      postcardEditor.imgly.nonDefaultPreviewSettings()
    }
    .navigationViewStyle(.stack)
  }
}
