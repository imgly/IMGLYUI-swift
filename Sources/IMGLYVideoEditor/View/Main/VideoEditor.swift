@_spi(Internal) import struct IMGLYCore.Error
@_spi(Internal) import IMGLYEditor
import IMGLYEngine
import SwiftUI

@_exported import IMGLYEditor

public struct VideoEditor: View {
  public static let defaultScene = Bundle.module.url(forResource: "video-empty", withExtension: "scene")!

  @Environment(\.imglyOnCreate) private var onCreate
  private let settings: EngineSettings

  public init(_ settings: EngineSettings) {
    self.settings = settings
  }

  public var body: some View {
    EditorUI(zoomPadding: 1)
      .navigationTitle("")
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          HStack(spacing: 16) {
            UndoRedoButtons()
            ExportButton()
          }
          .labelStyle(.adaptiveIconOnly)
        }
      }
      .imgly.editor(settings, behavior: .video)
      .imgly.onCreate { engine in
        guard let onCreate else {
          try await OnCreate.loadScene(from: Self.defaultScene)(engine)
          return
        }
        try await onCreate(engine)
      }
  }
}

struct VideoUI_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
