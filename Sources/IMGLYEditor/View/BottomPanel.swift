import SwiftUI
@_spi(Internal) import IMGLYCore
import IMGLYEngine

// MARK: - Environment Value

@_spi(Internal) public extension EnvironmentValues {
  @Entry var imglyBottomPanel: BottomPanel.Content?
  @Entry var imglyBottomPanelAnimation: Animation = .imgly.timelineMinimizeMaximize
}

/// A namespace for the bottom panel component.
@_spi(Internal) public enum BottomPanel {
  struct State: EditorState {
    let isCreating: Bool
    let isExporting: Bool
    let viewMode: EditorViewMode
  }
}

// MARK: - Bottom Panel Context

@_spi(Internal) public extension BottomPanel {
  /// The context for bottom panel components.
  struct Context: EditorContext {
    /// The engine of the current editor.
    @_spi(Internal) public let engine: Engine
    @_spi(Internal) public let eventHandler: EditorEventHandler
    /// The state of the current editor.
    @_spi(Internal) public let state: EditorState
  }

  /// A closure to build a bottom panel.
  typealias Content = Context.To<any View>
}
