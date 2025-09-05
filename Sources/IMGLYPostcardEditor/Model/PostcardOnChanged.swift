@_spi(Internal) import IMGLYEditor

extension Postcard.OnChanged {
  /// The default callback that handles editor state updates.
  ///
  /// The following state updates are handled:
  /// - `EditorStateChange.gestureActive`: Shows or hides the outline depending on whether a gesture is active.
  ///
  /// All other updates are forwarded to `OnChanged.default`.
  static let `default`: IMGLYEditor.OnChanged.Callback = { update, context in
    switch update {
    case let .page(_, newValue):
      try context.engine.showPage(newValue, historyResetBehavior: .always, deselectAll: true)
    default:
      try OnChanged.default(update, context)
    }
  }
}
