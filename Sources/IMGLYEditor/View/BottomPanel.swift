import SwiftUI
@_spi(Internal) import IMGLYCore
import IMGLYEngine

/// A namespace for the bottom panel component.
public enum BottomPanel {
  struct State: EditorState {
    let isCreating: Bool
    let isExporting: Bool
    let viewMode: EditorViewMode
  }
}

// MARK: - Bottom Panel Context

public extension BottomPanel {
  /// The context for bottom panel components.
  struct Context: EditorContext {
    /// The engine of the current editor.
    public let engine: Engine
    public let eventHandler: EditorEventHandler
    /// The state of the current editor.
    public let state: EditorState
  }

  /// A closure to build a bottom panel.
  typealias Content = Context.To<any View>
}
