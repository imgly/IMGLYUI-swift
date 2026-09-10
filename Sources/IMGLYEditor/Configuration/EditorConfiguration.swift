import IMGLYCoreUI
import IMGLYEngine
import SwiftUI

// MARK: - EditorConfiguration

/// A composable editor configuration.
///
/// Subclass this to create reusable configurations. Override computed properties to
/// customize callbacks, UI components, and other editor settings.
@MainActor
open class EditorConfiguration {
  private let builder: Builder

  // MARK: - Callbacks

  /// The `onCreate` handler.
  open var onCreate: OnCreate.Handler? { builder.onCreate }

  /// The `onExport` handler.
  open var onExport: OnExport.Handler? { builder.onExport }

  /// The `onUpload` handler.
  open var onUpload: OnUpload.Handler? { builder.onUpload }

  /// The `onClose` handler.
  open var onClose: OnClose.Handler? { builder.onClose }

  /// The `onError` handler.
  open var onError: OnError.Handler? { builder.onError }

  /// The `onLoaded` handler.
  open var onLoaded: OnLoaded.Handler? { builder.onLoaded }

  /// The `onChanged` handler.
  open var onChanged: OnChanged.Handler? { builder.onChanged }

  // MARK: - Components

  /// The dock configuration.
  open var dock: Dock.Configuration? { builder.dock }

  /// The inspector bar configuration.
  open var inspectorBar: InspectorBar.Configuration? { builder.inspectorBar }

  /// The canvas menu configuration.
  open var canvasMenu: CanvasMenu.Configuration? { builder.canvasMenu }

  /// The navigation bar configuration.
  open var navigationBar: NavigationBar.Configuration? { builder.navigationBar }

  /// The asset library configuration.
  open var assetLibrary: AssetLibraryConfiguration? { builder.assetLibrary }

  /// The bottom panel configuration.
  open var bottomPanel: BottomPanel.Configuration? { builder.bottomPanel }

  // MARK: - Other

  /// The color palette.
  open var colorPalette: [NamedColor]? { builder.colorPalette }

  /// The zoom padding for the canvas.
  open var zoomPadding: CGFloat? { builder.zoomPadding }

  /// Creates a configuration with optional customizations.
  ///
  /// The closure receives a ``Builder`` instance, allowing you to
  /// override specific properties while keeping the subclass defaults for everything else.
  ///
  /// - Parameter customize: A closure that configures the builder.
  public init(_ customize: (_ builder: Builder) -> Void = { _ in }) {
    let builder = Builder()
    self.builder = builder
    // Pre-populate builder with subclass defaults so that builder methods
    // merge with (rather than replace) subclass-provided configurations.
    builder.prepopulateDefaults(from: self)
    customize(builder)
  }
}

// MARK: - Builder

public extension EditorConfiguration {
  /// Builder for editor configuration.
  @MainActor
  final class Builder {
    // MARK: - Callbacks

    private(set) var onCreate: OnCreate.Handler?
    private(set) var onExport: OnExport.Handler?
    private(set) var onUpload: OnUpload.Handler?
    private(set) var onClose: OnClose.Handler?
    private(set) var onError: OnError.Handler?
    private(set) var onLoaded: OnLoaded.Handler?
    private(set) var onChanged: OnChanged.Handler?

    // MARK: - Components

    private(set) var dock: Dock.Configuration?
    private(set) var inspectorBar: InspectorBar.Configuration?
    private(set) var canvasMenu: CanvasMenu.Configuration?
    private(set) var navigationBar: NavigationBar.Configuration?
    private(set) var assetLibrary: AssetLibraryConfiguration?
    private(set) var bottomPanel: BottomPanel.Configuration?

    // MARK: - Other

    private(set) var colorPalette: [NamedColor]?
    private(set) var zoomPadding: CGFloat?

    /// Creates an empty builder.
    public init() {}

    /// Pre-populates the builder with subclass-provided defaults.
    /// Called during `EditorConfiguration.init` before the customize closure runs.
    func prepopulateDefaults(from config: EditorConfiguration) {
      dock = config.dock
      inspectorBar = config.inspectorBar
      canvasMenu = config.canvasMenu
      navigationBar = config.navigationBar
      assetLibrary = config.assetLibrary
      bottomPanel = config.bottomPanel
    }

    // MARK: - Callback Methods

    /// Sets the `onCreate` handler.
    public func onCreate(_ handler: @escaping OnCreate.Handler) {
      onCreate = handler
    }

    /// Sets the `onExport` handler.
    public func onExport(_ handler: @escaping OnExport.Handler) {
      onExport = handler
    }

    /// Sets the `onUpload` handler.
    public func onUpload(_ handler: @escaping OnUpload.Handler) {
      onUpload = handler
    }

    /// Sets the `onClose` handler.
    public func onClose(_ handler: @escaping OnClose.Handler) {
      onClose = handler
    }

    /// Sets the `onError` handler.
    public func onError(_ handler: @escaping OnError.Handler) {
      onError = handler
    }

    /// Sets the `onLoaded` handler.
    public func onLoaded(_ handler: @escaping OnLoaded.Handler) {
      onLoaded = handler
    }

    /// Sets the `onChanged` handler.
    public func onChanged(_ handler: @escaping OnChanged.Handler) {
      onChanged = handler
    }

    // MARK: - Component Methods

    /// Sets the dock configuration. Merges with any existing configuration (e.g., subclass defaults).
    public func dock(_ configure: (_ builder: inout Dock.Configuration.Builder) -> Void) {
      if let existing = dock {
        dock = Dock.Configuration { dockBuilder in
          dockBuilder.items = existing.items
          dockBuilder.modifications = existing.modifications
          dockBuilder.alignment = existing.alignment
          dockBuilder.backgroundColor = existing.backgroundColor
          dockBuilder.scrollDisabled = existing.scrollDisabled
          configure(&dockBuilder)
        }
      } else {
        dock = Dock.Configuration(configure)
      }
    }

    /// Sets the inspector bar configuration. Merges with any existing configuration.
    public func inspectorBar(_ configure: (_ builder: inout InspectorBar.Configuration.Builder) -> Void) {
      if let existing = inspectorBar {
        inspectorBar = InspectorBar.Configuration { inspectorBarBuilder in
          inspectorBarBuilder.items = existing.items
          inspectorBarBuilder.modifications = existing.modifications
          inspectorBarBuilder.enabled = existing.enabled
          configure(&inspectorBarBuilder)
        }
      } else {
        inspectorBar = InspectorBar.Configuration(configure)
      }
    }

    /// Sets the canvas menu configuration. Merges with any existing configuration.
    public func canvasMenu(_ configure: (_ builder: inout CanvasMenu.Configuration.Builder) -> Void) {
      if let existing = canvasMenu {
        canvasMenu = CanvasMenu.Configuration { canvasMenuBuilder in
          canvasMenuBuilder.items = existing.items
          canvasMenuBuilder.modifications = existing.modifications
          configure(&canvasMenuBuilder)
        }
      } else {
        canvasMenu = CanvasMenu.Configuration(configure)
      }
    }

    /// Sets the navigation bar configuration. Merges with any existing configuration.
    public func navigationBar(_ configure: (_ builder: inout NavigationBar.Configuration.Builder) -> Void) {
      if let existing = navigationBar {
        navigationBar = NavigationBar.Configuration { navigationBarBuilder in
          navigationBarBuilder.items = existing.items
          navigationBarBuilder.modifications = existing.modifications
          configure(&navigationBarBuilder)
        }
      } else {
        navigationBar = NavigationBar.Configuration(configure)
      }
    }

    /// Sets the asset library configuration. Merges with any existing configuration.
    public func assetLibrary(_ configure: (_ builder: inout AssetLibraryConfiguration.Builder) -> Void) {
      if let existing = assetLibrary {
        assetLibrary = AssetLibraryConfiguration { assetLibraryBuilder in
          assetLibraryBuilder.categories = existing.categories
          assetLibraryBuilder.view = existing.view
          assetLibraryBuilder.modifications = existing.modifications
          assetLibraryBuilder.includeAVResources = existing.includeAVResources
          configure(&assetLibraryBuilder)
        }
      } else {
        assetLibrary = AssetLibraryConfiguration(configure)
      }
    }

    /// Sets the bottom panel configuration. Merges with any existing configuration.
    public func bottomPanel(_ configure: (_ builder: inout BottomPanel.Configuration.Builder) -> Void) {
      if let existing = bottomPanel {
        bottomPanel = BottomPanel.Configuration { bottomPanelBuilder in
          bottomPanelBuilder.content = existing.content
          bottomPanelBuilder.animation = existing.animation
          configure(&bottomPanelBuilder)
        }
      } else {
        bottomPanel = BottomPanel.Configuration(configure)
      }
    }

    /// Sets the color palette.
    public func colorPalette(_ colors: [NamedColor]) {
      colorPalette = colors
    }

    /// Sets the zoom padding for the canvas.
    public func zoomPadding(_ padding: CGFloat) {
      zoomPadding = padding
    }
  }
}

// MARK: - Internal Configuration

extension EditorConfiguration {
  // swiftlint:disable:next cyclomatic_complexity
  func configure(_ composer: EditorConfigurationComposer) {
    // Builder values take precedence over subclass overrides.
    if let handler = builder.onCreate ?? onCreate { composer.onCreate(handler) }
    if let handler = builder.onExport ?? onExport { composer.onExport(handler) }
    if let handler = builder.onUpload ?? onUpload { composer.onUpload(handler) }
    if let handler = builder.onClose ?? onClose { composer.onClose(handler) }
    if let handler = builder.onError ?? onError { composer.onError(handler) }
    if let handler = builder.onLoaded ?? onLoaded { composer.onLoaded(handler) }
    if let handler = builder.onChanged ?? onChanged { composer.onChanged(handler) }

    if let dock = builder.dock ?? dock {
      composer.dock { dockBuilder in
        if let items = dock.items { dockBuilder.items = items }
        for modification in dock.modifications {
          dockBuilder.modify(modification)
        }
        if let alignment = dock.alignment { dockBuilder.alignment = alignment }
        if let backgroundColor = dock.backgroundColor { dockBuilder.backgroundColor = backgroundColor }
        if let scrollDisabled = dock.scrollDisabled { dockBuilder.scrollDisabled = scrollDisabled }
      }
    }
    if let inspectorBar = builder.inspectorBar ?? inspectorBar {
      composer.inspectorBar { inspectorBarBuilder in
        if let items = inspectorBar.items { inspectorBarBuilder.items = items }
        for modification in inspectorBar.modifications {
          inspectorBarBuilder.modify(modification)
        }
        if let enabled = inspectorBar.enabled { inspectorBarBuilder.enabled = enabled }
      }
    }
    if let canvasMenu = builder.canvasMenu ?? canvasMenu {
      composer.canvasMenu { canvasMenuBuilder in
        if let items = canvasMenu.items { canvasMenuBuilder.items = items }
        for modification in canvasMenu.modifications {
          canvasMenuBuilder.modify(modification)
        }
      }
    }
    if let navigationBar = builder.navigationBar ?? navigationBar {
      composer.navigationBar { navigationBarBuilder in
        if let items = navigationBar.items { navigationBarBuilder.items = items }
        for modification in navigationBar.modifications {
          navigationBarBuilder.modify(modification)
        }
      }
    }
    if let assetLibrary = builder.assetLibrary ?? assetLibrary {
      composer.assetLibrary { assetLibraryBuilder in
        if let categories = assetLibrary.categories { assetLibraryBuilder.categories = categories }
        if let view = assetLibrary.view { assetLibraryBuilder.view = view }
        for modification in assetLibrary.modifications {
          assetLibraryBuilder.modify(modification)
        }
        if assetLibrary.includeAVResources { assetLibraryBuilder.includeAVResources = true }
      }
    }
    if let bottomPanel = builder.bottomPanel ?? bottomPanel {
      composer.bottomPanel { bottomPanelBuilder in
        if let content = bottomPanel.content { bottomPanelBuilder.content = content }
        if let animation = bottomPanel.animation { bottomPanelBuilder.animation = animation }
      }
    }

    if let palette = builder.colorPalette ?? colorPalette { composer.colorPalette = palette }
    if let padding = builder.zoomPadding ?? zoomPadding { composer.zoomPadding = padding }
  }
}

// MARK: - Result Builder

typealias EditorConfigurationResultBuilder = ArrayBuilder<EditorConfiguration>
