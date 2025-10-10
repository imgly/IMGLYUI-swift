@_spi(Internal) import IMGLYEditor

extension OnChanged {
  /// The default callback that handles editor state updates for the ``PhotoEditor``.
  ///
  /// The following state updates are handled:
  /// - `EditorStateChange.editMode`: Shows or hides the outline and crop handles and modifies the corresponding
  /// `"layer/resize"` scope of the page depending on the edit mode.
  ///
  /// All other updates are forwarded to `OnChanged.default`.
  static let photoEditorDefault: IMGLYEditor.OnChanged.Callback = { update, context in
    switch update {
    case let .editMode(oldValue, newValue):
      guard oldValue != newValue else { return }

      let isCrop = newValue == .crop
      if let page = try context.engine.scene.getPages().first {
        try context.engine.editor.setHighlightingEnabled(page, enabled: isCrop)
        try context.engine.block.setScopeEnabled(page, scope: .key(.layerResize), enabled: isCrop)
      }
    default:
      try OnChanged.default(update, context)
    }
  }
}
