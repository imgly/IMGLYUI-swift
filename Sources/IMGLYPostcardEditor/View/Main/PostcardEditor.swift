@_spi(Internal) import IMGLYEditor
import SwiftUI

/// Built to facilitate optimal post- & greeting- card design, from changing accent colors and selecting fonts to custom
/// messages and pictures.
public struct PostcardEditor: View {
  /// Scene that will be loaded by the default implementation of the `onCreate` callback.
  public static let defaultScene = Bundle.module.url(forResource: "postcard-empty", withExtension: "scene")!

  @Environment(\.imglyOnCreate) private var onCreate
  @Environment(\.imglyNavigationBarItems) private var navigationBarItems
  private let settings: EngineSettings

  /// Creates a postcard editor with settings.
  /// - Parameter settings: The settings to initialize the underlying engine.
  public init(_ settings: EngineSettings) {
    self.settings = settings
  }

  public var body: some View {
    EditorUI()
      .navigationTitle("")
      .imgly.editor(settings, behavior: .postcard)
      .imgly.onCreate { engine in
        guard let onCreate else {
          try await OnCreate.loadScene(from: Self.defaultScene)(engine)
          return
        }
        try await onCreate(engine)
      }
      .imgly.navigationBarItems { context in
        if let navigationBarItems {
          try navigationBarItems(context)
        } else {
          NavigationBar.ItemGroup(placement: .topBarLeading) {
            NavigationBar.Buttons.closeEditor()
            NavigationBar.Buttons.previousPage(
              label: { _ in NavigationLabel("Design", direction: .backward) }
            )
          }
          NavigationBar.ItemGroup(placement: .principal) {
            NavigationBar.Buttons.undo()
            NavigationBar.Buttons.redo()
            NavigationBar.Buttons.togglePreviewMode()
          }
          NavigationBar.ItemGroup(placement: .topBarTrailing) {
            NavigationBar.Buttons.nextPage(
              label: { _ in NavigationLabel("Write", direction: .forward) }
            )
            NavigationBar.Buttons.export()
          }
        }
      }
  }
}

struct PostcardUI_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
