@_spi(Internal) import IMGLYEditor
import SwiftUI

@_exported import IMGLYEditor

public struct DesignEditor: View {
  public static let defaultScene = Bundle.module.url(forResource: "design-ui-empty", withExtension: "scene")!

  @Environment(\.imglyOnCreate) private var onCreate
  private let settings: EngineSettings

  public init(_ settings: EngineSettings) {
    self.settings = settings
  }

  public var body: some View {
    EditorUI()
      .navigationTitle("")
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          HStack(spacing: 16) {
            UndoRedoButtons()
            PreviewButton()
            ExportButton()
          }
          .labelStyle(.adaptiveIconOnly)
        }
      }
      .imgly.editor(settings, behavior: .design)
      .imgly.onCreate { engine in
        guard let onCreate else {
          try await OnCreate.loadScene(from: Self.defaultScene)(engine)
          return
        }
        try await onCreate(engine)
      }
      .imgly.pageNavigation(true)
  }
}

struct DesignEditor_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
