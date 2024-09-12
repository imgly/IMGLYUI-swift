@_spi(Internal) import IMGLYEditor
@_spi(Internal) import struct IMGLYCore.Error
import SwiftUI

/// Built to support versatile photo editing capabilities.
public struct PhotoEditor: View {
  /// Image that will be loaded by the default implementation of the `onCreate` callback.
  public static let defaultImage = Bundle.module.url(forResource: "photo-ui-empty", withExtension: "png")!

  @Environment(\.imglyOnCreate) private var onCreate
  @Environment(\.imglyOnExport) private var onExport
  private let settings: EngineSettings

  /// Creates a photo editor with settings.
  /// - Parameter settings: The settings to initialize the underlying engine.
  public init(_ settings: EngineSettings) {
    self.settings = settings
  }

  public var body: some View {
    EditorUI(zoomPadding: 0)
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
      .imgly.editor(settings, behavior: .photo)
      .imgly.onCreate { engine in
        guard let onCreate else {
          try await OnCreate.loadImage(from: Self.defaultImage)(engine)
          return
        }
        try await onCreate(engine)
      }
      .imgly.onExport { engine, eventHandler in
        guard let onExport else {
          try await OnExport.default(mimeType: .png)(engine, eventHandler)
          return
        }
        try await onExport(engine, eventHandler)
      }
      .imgly.pageNavigation(true)
  }
}

public extension OnCreate {
  /// Creates a callback that loads an image as scene and the default and demo asset sources.
  /// - Parameters:
  ///   - url: The URL of the image file.
  ///   - size: Optional size to crop the image.
  /// - Returns: The callback.
  static func loadImage(from url: URL, size: CGSize? = nil) -> Callback {
    { engine in
      try await engine.scene.create(fromImage: url)
      try await loadAssetSources(engine)

      let graphics = try engine.block.find(byType: .graphic)
      guard let image = graphics.first, graphics.count == 1 else {
        throw Error(errorDescription: "No image found.")
      }
      let pages = try engine.scene.getPages()
      guard let page = pages.first, pages.count == 1 else {
        throw Error(errorDescription: "No page found.")
      }

      try engine.block.setFill(page, fill: engine.block.getFill(image))
      try engine.block.destroy(image)

      if let size {
        try engine.block.setWidth(page, value: Float(size.width))
        try engine.block.setHeight(page, value: Float(size.height))
      }
    }
  }
}

struct PhotoEditor_Previews: PreviewProvider {
  static var previews: some View {
    defaultPreviews
  }
}
