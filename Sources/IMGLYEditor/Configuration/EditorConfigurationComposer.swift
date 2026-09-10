@_spi(Internal) import IMGLYCoreUI
import SwiftUI

// MARK: - EditorConfigurationComposer

/// A composer for accumulating editor configuration.
///
/// This composer is passed to each `EditorConfiguration.configure(_:)` method in sequence.
@MainActor
final class EditorConfigurationComposer {
  // MARK: - Callbacks

  private var onCreate: OnCreate.Callback?
  private var onExport: OnExport.Callback?
  private var onUpload: OnUpload.Callback?
  private var onClose: OnClose.Callback?
  private var onError: OnError.Callback?
  private var onLoaded: OnLoaded.Callback?
  private var onChanged: OnChanged.Callback?

  // MARK: - Component Builders

  private var dock = Dock.Configuration.Builder()
  private var inspectorBar = InspectorBar.Configuration.Builder()
  private var canvasMenu = CanvasMenu.Configuration.Builder()
  private var navigationBar = NavigationBar.Configuration.Builder()
  private var assetLibrary = AssetLibraryConfiguration.Builder()
  private var bottomPanel = BottomPanel.Configuration.Builder()

  // MARK: - Simple Value Properties

  /// The color palette to use.
  var colorPalette: [NamedColor]?

  /// The zoom padding to use.
  var zoomPadding: CGFloat?

  // MARK: - Component Configuration Methods

  /// Configures the dock.
  ///
  /// Use the builder to set items, alignment, background color, and modifications.
  ///
  /// - Parameter configure: A closure that configures the dock builder.
  func dock(_ configure: (inout Dock.Configuration.Builder) -> Void) {
    configure(&dock)
  }

  /// Configures the inspector bar.
  ///
  /// Use the builder to set items, enabled state, and modifications.
  ///
  /// - Parameter configure: A closure that configures the inspector bar builder.
  func inspectorBar(_ configure: (inout InspectorBar.Configuration.Builder) -> Void) {
    configure(&inspectorBar)
  }

  /// Configures the canvas menu.
  ///
  /// Use the builder to set items and modifications.
  ///
  /// - Parameter configure: A closure that configures the canvas menu builder.
  func canvasMenu(_ configure: (inout CanvasMenu.Configuration.Builder) -> Void) {
    configure(&canvasMenu)
  }

  /// Configures the navigation bar.
  ///
  /// Use the builder to set items and modifications.
  ///
  /// - Parameter configure: A closure that configures the navigation bar builder.
  func navigationBar(_ configure: (inout NavigationBar.Configuration.Builder) -> Void) {
    configure(&navigationBar)
  }

  /// Configures the asset library.
  ///
  /// Use the builder to set a custom view and/or modify categories.
  ///
  /// - Parameter configure: A closure that configures the asset library builder.
  func assetLibrary(_ configure: (inout AssetLibraryConfiguration.Builder) -> Void) {
    configure(&assetLibrary)
  }

  /// Configures the bottom panel.
  ///
  /// Use the builder to set custom content and animation.
  ///
  /// - Parameter configure: A closure that configures the bottom panel builder.
  func bottomPanel(_ configure: (inout BottomPanel.Configuration.Builder) -> Void) {
    configure(&bottomPanel)
  }

  // MARK: - Callback Setters

  /// Sets the `onCreate` callback.
  ///
  /// The handler receives the engine and an `existing` closure. Call `existing()` to invoke
  /// any previously configured `onCreate` callbacks.
  ///
  /// - Parameter handler: The handler to set.
  func onCreate(_ handler: @escaping OnCreate.Handler) {
    let previous = onCreate
    onCreate = { engine in
      try await handler(engine) {
        try await previous?(engine)
      }
    }
  }

  /// Sets the `onExport` callback.
  ///
  /// The handler receives the engine, event handler, and an `existing` closure.
  /// Call `existing()` to invoke any previously configured `onExport` callbacks.
  ///
  /// - Parameter handler: The handler to set.
  func onExport(_ handler: @escaping OnExport.Handler) {
    let previous = onExport
    onExport = { engine, eventHandler in
      try await handler(engine, eventHandler) {
        try await previous?(engine, eventHandler)
      }
    }
  }

  /// Sets the `onUpload` callback.
  ///
  /// The handler receives the engine, source ID, asset, and an `existing` closure.
  /// Call `existing(asset)` to pass the asset through previously configured handlers.
  ///
  /// - Parameter handler: The handler to set.
  func onUpload(_ handler: @escaping OnUpload.Handler) {
    let previous = onUpload
    onUpload = { engine, sourceID, asset in
      try await handler(engine, sourceID, asset) { modifiedAsset in
        if let previous {
          return try await previous(engine, sourceID, modifiedAsset)
        }
        return modifiedAsset
      }
    }
  }

  /// Sets the `onClose` callback.
  ///
  /// The handler receives the engine, event handler, and an `existing` closure.
  /// Call `existing()` to invoke any previously configured `onClose` callbacks.
  ///
  /// - Parameter handler: The handler to set.
  func onClose(_ handler: @escaping OnClose.Handler) {
    let previous = onClose
    onClose = { engine, eventHandler in
      handler(engine, eventHandler) {
        previous?(engine, eventHandler)
      }
    }
  }

  /// Sets the `onError` callback.
  ///
  /// The handler receives the error, event handler, and an `existing` closure.
  /// Call `existing()` to invoke any previously configured `onError` callbacks.
  ///
  /// - Parameter handler: The handler to set.
  func onError(_ handler: @escaping OnError.Handler) {
    let previous = onError
    onError = { error, eventHandler in
      handler(error, eventHandler) {
        previous?(error, eventHandler)
      }
    }
  }

  /// Sets the `onLoaded` callback.
  ///
  /// The handler receives the context and an `existing` closure.
  /// Call `existing()` to invoke any previously configured `onLoaded` callbacks.
  ///
  /// - Parameter handler: The handler to set.
  func onLoaded(_ handler: @escaping OnLoaded.Handler) {
    let previous = onLoaded
    onLoaded = { context in
      try await handler(context) {
        try await previous?(context)
      }
    }
  }

  /// Sets the `onChanged` callback.
  ///
  /// The handler receives the update, context, and an `existing` closure.
  /// Call `existing()` to invoke any previously configured `onChanged` callbacks.
  ///
  /// - Parameter handler: The handler to set.
  func onChanged(_ handler: @escaping OnChanged.Handler) {
    let previous = onChanged
    onChanged = { update, context in
      try handler(update, context) {
        try previous?(update, context)
      }
    }
  }

  init() {}

  /// Builds the final environment structure.
  func build() -> EditorEnvironment {
    var env = EditorEnvironment()

    // Callbacks
    env.onCreate = onCreate
    env.onExport = onExport
    env.onUpload = onUpload
    env.onClose = onClose
    env.onError = onError
    env.onLoaded = onLoaded
    env.onChanged = onChanged

    // Dock
    env.dockItems = dock.items
    env.dockModifications = dock.modifications
    env.dockItemAlignment = dock.alignment
    env.dockBackgroundColor = dock.backgroundColor
    env.dockScrollDisabled = dock.scrollDisabled

    // InspectorBar
    env.inspectorBarItems = inspectorBar.items
    env.inspectorBarModifications = inspectorBar.modifications
    env.inspectorBarEnabled = inspectorBar.enabled

    // CanvasMenu
    env.canvasMenuItems = canvasMenu.items
    env.canvasMenuModifications = canvasMenu.modifications

    // NavigationBar
    env.navigationBarItems = navigationBar.items
    env.navigationBarModifications = navigationBar.modifications

    // AssetLibrary
    env.assetLibraryCategories = assetLibrary.categories
    env.assetLibrary = assetLibrary.view
    env.assetLibraryModifications = assetLibrary.modifications
    env.includeAVResources = assetLibrary.includeAVResources

    // BottomPanel
    env.bottomPanel = bottomPanel.content
    env.bottomPanelAnimation = bottomPanel.animation

    // Other
    env.colorPalette = colorPalette
    env.zoomPadding = zoomPadding

    return env
  }
}
