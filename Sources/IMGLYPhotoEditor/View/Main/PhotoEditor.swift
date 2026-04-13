@_spi(Internal) import IMGLYEditor
import IMGLYEngine
@_spi(Internal) import struct IMGLYCore.Error
import SwiftUI

/// Built to support versatile photo editing capabilities.
public struct PhotoEditor: View {
  /// Image that will be loaded by the default implementation of the `onCreate` callback.
  public static let defaultImage = Bundle.module.url(forResource: "photo-ui-empty", withExtension: "png")!

  @Environment(\.imglyOnCreate) private var onCreate
  @Environment(\.imglyOnLoaded) private var onLoaded
  @Environment(\.imglyOnChanged) private var onChanged
  @Environment(\.imglyOnExport) private var onExport
  @Environment(\.imglyNavigationBarItems) private var navigationBarItems
  @Environment(\.imglyDockItems) private var dockItems
  private let settings: EngineSettings

  /// Creates a photo editor with settings.
  /// - Parameter settings: The settings to initialize the underlying engine.
  public init(_ settings: EngineSettings) {
    self.settings = settings
  }

  public var body: some View {
    EditorUI(zoomPadding: 0)
      .navigationTitle("")
      .imgly.editor(settings, behavior: .photo)
      .imgly.onCreate { engine in
        guard let onCreate else {
          try await OnCreate.loadImage(from: Self.defaultImage)(engine)
          return
        }
        try await onCreate(engine)
      }
      .imgly.onLoaded { context in
        guard let onLoaded else {
          try await OnLoaded.photoEditorDefault(context)
          return
        }
        try await onLoaded(context)
      }
      .imgly.onChanged { update, context in
        guard let onChanged else {
          try OnChanged.photoEditorDefault(update, context)
          return
        }
        try onChanged(update, context)
      }
      .imgly.onExport { engine, eventHandler in
        guard let onExport else {
          try await OnExport.default(mimeType: .png)(engine, eventHandler)
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
            NavigationBar.Buttons.togglePreviewMode()
            NavigationBar.Buttons.export()
          }
        }
      }
      .imgly.dockItems { context in
        if let dockItems {
          try dockItems(context)
        } else {
          Dock.Buttons.adjustments()
          Dock.Buttons.filter()
          Dock.Buttons.effect()
          Dock.Buttons.blur()
          Dock.Buttons.crop()
          Dock.Buttons.textLibrary()
          Dock.Buttons.shapesLibrary()
          Dock.Buttons.stickersLibrary()
        }
      }
      .imgly.inspectorBarEnabled {
        try $0.engine.block.getType($0.selection.block) != DesignBlockType.page.rawValue
      }
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

      let pages = try engine.scene.getPages()
      guard let page = pages.first, pages.count == 1 else {
        throw Error(errorDescription: "No page found.")
      }

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
