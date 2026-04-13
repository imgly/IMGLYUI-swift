@_spi(Internal) import IMGLYEditor

public extension OnLoaded {
  /// The default callback implementation for the `OnLoaded.Callback` for the ``PhotoEditor``.
  ///
  /// Subscribes to the `EditorAPI.onHistoryUpdated` and shows or hides the outline and crop handles and modifies the
  /// corresponding `"layer/resize"` scope of the page depending on the edit mode.
  static let photoEditorDefault: IMGLYEditor.OnLoaded.Callback = { context in
    for try await _ in context.engine.editor.onHistoryUpdated {
      let editMode = context.engine.editor.getEditMode()
      let isCrop = editMode == .crop
      if let page = try context.engine.scene.getPages().first {
        try context.engine.editor.setHighlightingEnabled(page, enabled: isCrop)
        try context.engine.block.setScopeEnabled(page, scope: .key(.layerResize), enabled: isCrop)
      }
    }
  }
}
