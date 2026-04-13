@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import IMGLYEditor
import SwiftUI

extension PreviewProvider {
  private static var url: URL {
    getResource("apparel-ui-b-1", withExtension: "scene")
  }

  @ViewBuilder static var apparelEditor: some View {
    NavigationView {
      getSecrets { secrets in
        ApparelEditor(.init(license: secrets.licenseKey, userID: "swiftui-preview-user"))
          .imgly.onCreate(OnCreate.loadScene(from: url))
      }
    }
  }

  @ViewBuilder static var defaultPreviews: some View {
    Group {
      apparelEditor
      apparelEditor.imgly.nonDefaultPreviewSettings()
    }
    .navigationViewStyle(.stack)
  }
}
