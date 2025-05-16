/// A type for the state of the editor.
@MainActor
public protocol EditorState {
  /// Indicates that the ``IMGLY/onCreate(_:)`` callback did not yet complete.
  var isCreating: Bool { get }
  /// Indicates that the ``IMGLY/onExport(_:)`` callback is running.
  var isExporting: Bool { get }
  /// The view mode of the editor.
  var viewMode: EditorViewMode { get }
}

/// The view mode of the editor.
public enum EditorViewMode {
  /// Editing mode of the editor.
  /// - Note: Best used in all editor solutions.
  case edit
  /// Preview mode of the editor that previews the current design.
  /// - Note: Best used with `IMGLYPhotoEditor`, `IMGLYApparelEditor`, and `IMGLYPostcardEditor`.
  case preview
  /// Pages mode of the editor that displays thumbnails of all the pages in a grid.
  /// - Note: Best used with `IMGLYDesignEditor`.
  case pages
}
