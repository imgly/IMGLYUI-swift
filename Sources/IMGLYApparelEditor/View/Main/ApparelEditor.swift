@_spi(Internal) import IMGLYEditor
import SwiftUI

/// Custom, mobile apparel UI for creating a print-ready design. The editable page is overlaid on a t-shirt mockup to
/// give users an idea of where to position elements.
public struct ApparelEditor: View {
  /// Scene that will be loaded by the default implementation of the `onCreate` callback.
  public static let defaultScene = Bundle.module.url(forResource: "apparel-ui-b-empty", withExtension: "scene")!

  @Environment(\.imglyOnCreate) private var onCreate
  @Environment(\.imglyNavigationBarItems) private var navigationBarItems
  private let settings: EngineSettings

  /// Creates an apparel editor with settings.
  /// - Parameter settings: The settings to initialize the underlying engine.
  public init(_ settings: EngineSettings) {
    self.settings = settings
  }

  public var body: some View {
    EditorUI()
      .navigationTitle("")
      .imgly.editor(settings, behavior: .apparel)
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
          }
          NavigationBar.ItemGroup(placement: .topBarTrailing) {
            NavigationBar.Buttons.undo()
            NavigationBar.Buttons.redo()
            NavigationBar.Buttons.togglePreviewMode()
            NavigationBar.Buttons.export()
          }
        }
      }
  }
}

struct ApparelUI_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
