@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYCoreUI
import SwiftUI

extension PreviewProvider {
  private static var url: URL {
    getResource("apparel-ui-b-1", withExtension: "scene")
  }

  @ViewBuilder static var defaultPreviews: some View {
    defaultPreviews()
  }

  @ViewBuilder static func editorPreview(sheet: SheetState?) -> some View {
    NavigationView {
      getSecrets { secrets in
        let config = EngineConfiguration(
          settings: .init(license: secrets.licenseKey, userID: "swiftui-preview-user"),
          callbacks: .init(onCreate: OnCreate.loadScene(from: url))
        )
        EditorPreview(config, sheet: sheet)
      }
    }
  }

  @ViewBuilder static func defaultPreviews(sheet: SheetState? = nil) -> some View {
    Group {
      editorPreview(sheet: sheet)
      editorPreview(sheet: sheet).imgly.nonDefaultPreviewSettings()
    }
    .navigationViewStyle(.stack)
  }
}

private struct EditorPreview: View {
  @StateObject private var interactor: Interactor

  init(_ config: EngineConfiguration, sheet: SheetState?) {
    _interactor = .init(wrappedValue: Interactor(
      config: config,
      behavior: .default,
      assetLibrary: DefaultAssetLibrary(),
      sheet: sheet
    ))
  }

  var body: some View {
    EditorUI()
      .imgly.navigationBarItems { _ in
        NavigationBar.ItemGroup(placement: .topBarTrailing) {
          NavigationBar.Buttons.undo()
          NavigationBar.Buttons.redo()
          NavigationBar.Buttons.togglePreviewMode()
          NavigationBar.Buttons.export()
        }
      }
      .imgly.interactor(interactor)
  }
}
