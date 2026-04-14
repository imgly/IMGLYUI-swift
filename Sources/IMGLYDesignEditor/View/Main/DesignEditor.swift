@_spi(Internal) import IMGLYCore
@_spi(Internal) import IMGLYEditor
import SwiftUI

/// Built to support versatile editing capabilities for a broad range of design applications.
public struct DesignEditor: View {
  /// Scene that will be loaded by the default implementation of the `onCreate` callback.
  public static let defaultScene = Bundle.module.url(forResource: "design-ui-empty", withExtension: "scene")!

  @Environment(\.imglyOnCreate) private var onCreate
  @Environment(\.imglyOnExport) private var onExport
  @Environment(\.imglyNavigationBarItems) private var navigationBarItems
  @Environment(\.imglyDockItems) private var dockItems
  private let settings: EngineSettings

  /// Creates a design editor with settings.
  /// - Parameter settings: The settings to initialize the underlying engine.
  public init(_ settings: EngineSettings) {
    self.settings = settings
  }

  public var body: some View {
    EditorUI()
      .navigationTitle("")
      .imgly.editor(settings, behavior: .design)
      .imgly.onCreate { engine in
        guard let onCreate else {
          try await OnCreate.loadScene(from: Self.defaultScene)(engine)
          return
        }
        try await onCreate(engine)
      }
      .imgly.onExport { engine, eventHandler in
        guard let onExport else {
          try await OnExport.default(mimeType: FeatureFlags.isEnabled(.exportPNGInDesignEditor) ? .png : nil)(
            engine,
            eventHandler
          )
          return
        }
        try await onExport(engine, eventHandler)
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
            NavigationBar.Buttons.togglePagesMode()
            NavigationBar.Buttons.export()
          }
        }
      }
      .imgly.dockItems { context in
        if let dockItems {
          try dockItems(context)
        } else {
          Dock.Buttons.elementsLibrary()
          Dock.Buttons.photoRoll()
          Dock.Buttons.systemCamera()
          Dock.Buttons.imagesLibrary()
          Dock.Buttons.textLibrary()
          Dock.Buttons.shapesLibrary()
          Dock.Buttons.stickersLibrary()
          Dock.Buttons.resize()
        }
      }
  }
}

struct DesignEditor_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
