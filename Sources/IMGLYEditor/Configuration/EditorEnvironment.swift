@_spi(Internal) import IMGLYCoreUI
import SwiftUI

// MARK: - EditorEnvironment

/// A structure holding all editor environment values.
///
/// This is stored in the environment and accumulated through configurations.
/// Includes callbacks, UI component items/modifications, and other editor settings.
@_spi(Internal) public struct EditorEnvironment {
  // MARK: - Callbacks

  @_spi(Internal) public var onCreate: OnCreate.Callback?
  @_spi(Internal) public var onExport: OnExport.Callback?
  @_spi(Internal) public var onUpload: OnUpload.Callback?
  @_spi(Internal) public var onClose: OnClose.Callback?
  @_spi(Internal) public var onError: OnError.Callback?
  @_spi(Internal) public var onLoaded: OnLoaded.Callback?
  @_spi(Internal) public var onChanged: OnChanged.Callback?

  // MARK: - Dock

  @_spi(Internal) public var dockItems: Dock.Items?
  @_spi(Internal) public var dockModifications: [Dock.Modifications]
  @_spi(Internal) public var dockItemAlignment: Dock.Alignment?
  @_spi(Internal) public var dockBackgroundColor: Dock.BackgroundColor?
  @_spi(Internal) public var dockScrollDisabled: Dock.ScrollDisabled?

  // MARK: - InspectorBar

  @_spi(Internal) public var inspectorBarItems: InspectorBar.Items?
  @_spi(Internal) public var inspectorBarModifications: [InspectorBar.Modifications]
  @_spi(Internal) public var inspectorBarEnabled: InspectorBar.Enabled?

  // MARK: - CanvasMenu

  @_spi(Internal) public var canvasMenuItems: CanvasMenu.Items?
  @_spi(Internal) public var canvasMenuModifications: [CanvasMenu.Modifications]

  // MARK: - NavigationBar

  @_spi(Internal) public var navigationBarItems: NavigationBar.Items?
  @_spi(Internal) public var navigationBarModifications: [NavigationBar.Modifications]

  // MARK: - AssetLibrary

  @_spi(Internal) public var assetLibraryCategories: [AssetLibraryCategory]?
  @_spi(Internal) public var assetLibrary: (([AssetLibraryCategory]) -> any AssetLibrary)?
  @_spi(Internal) public var assetLibraryModifications: [CategoryModifications]
  @_spi(Internal) public var includeAVResources: Bool = false

  // MARK: - BottomPanel

  @_spi(Internal) public var bottomPanel: BottomPanel.Content?
  @_spi(Internal) public var bottomPanelAnimation: Animation?

  // MARK: - Other

  @_spi(Internal) public var colorPalette: [NamedColor]?
  @_spi(Internal) public var zoomPadding: CGFloat?

  @_spi(Internal) public init() {
    dockModifications = []
    inspectorBarModifications = []
    canvasMenuModifications = []
    navigationBarModifications = []
    assetLibraryModifications = []
  }

  // MARK: - Asset Library Helpers

  /// Applies all category modifications to the given categories.
  @MainActor
  private func applyAssetLibraryModifications(to categories: [AssetLibraryCategory]) throws -> [AssetLibraryCategory] {
    var result = categories
    for modification in assetLibraryModifications {
      let modifier = CategoryModifier()
      try modification(modifier)
      result = try modifier.apply(to: result)
    }
    return result
  }

  /// Creates the configured asset library view.
  ///
  /// This applies all category modifications to the configured categories
  /// (or default categories if none are configured), then creates the asset
  /// library view using the configured factory or the default `AssetLibraryView`.
  ///
  /// - Parameter defaultCategories: The default categories to use if none are configured.
  /// - Returns: The configured asset library view.
  @MainActor
  @_spi(Internal) public func makeAssetLibrary(defaultCategories: [AssetLibraryCategory]) -> any AssetLibrary {
    // Use configured categories if set, otherwise use defaults
    let baseCategories = assetLibraryCategories ?? defaultCategories

    var categories: [AssetLibraryCategory]
    do {
      categories = try applyAssetLibraryModifications(to: baseCategories)
    } catch {
      // Log the error and fall back to unmodified categories
      print("AssetLibrary modification error: \(error.localizedDescription)")
      categories = baseCategories
    }

    if !includeAVResources {
      categories.removeAll { $0.id == AssetLibraryCategory.ID.videos || $0.id == AssetLibraryCategory.ID.audio }
    }
    if let factory = assetLibrary {
      return factory(categories)
    }
    return AssetLibraryView(categories: categories, includeAVResources: includeAVResources)
  }
}

// MARK: - Environment Key

@_spi(Internal) public extension EnvironmentValues {
  @Entry var imglyEditorEnvironment: EditorEnvironment = .init()
}
