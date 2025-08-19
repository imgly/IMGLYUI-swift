@_spi(Internal) import IMGLYEditor
import SwiftUI

/// Built to support versatile video editing capabilities for a broad range of video applications.
public struct VideoEditor: View {
  /// Scene that will be loaded by the default implementation of the `onCreate` callback.
  public nonisolated static let defaultScene = Bundle.module.url(forResource: "video-empty", withExtension: "scene")!

  @Environment(\.imglyOnCreate) private var onCreate
  @Environment(\.imglyNavigationBarItems) private var navigationBarItems
  @Environment(\.imglyDockItems) private var dockItems
  private let settings: EngineSettings

  /// Creates a video editor with settings.
  /// - Parameter settings: The settings to initialize the underlying engine.
  public init(_ settings: EngineSettings) {
    self.settings = settings
  }

  public var body: some View {
    EditorUI(zoomPadding: 1)
      .navigationTitle("")
      .imgly.editor(settings, behavior: .video)
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
            NavigationBar.Buttons.export()
          }
        }
      }
      .imgly.dockItems { context in
        if let dockItems {
          try dockItems(context)
        } else {
          Dock.Buttons.photoRoll()
          Dock.Buttons.imglyCamera()
          Dock.Buttons.overlaysLibrary()
          Dock.Buttons.textLibrary()
          Dock.Buttons.stickersAndShapesLibrary()
          Dock.Buttons.audioLibrary()
          Dock.Buttons.voiceover()
          Dock.Buttons.reorder()
          Dock.Buttons.resize()
        }
      }
  }
}

struct VideoUI_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
