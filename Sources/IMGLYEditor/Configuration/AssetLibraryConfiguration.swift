@_spi(Internal) import IMGLYCoreUI
import SwiftUI

// MARK: - CategoryModifications

/// A closure that modifies library categories using a category modifier.
public typealias CategoryModifications = @MainActor (_ categories: CategoryModifier) throws -> Void

// MARK: - AssetLibraryConfiguration

/// Configuration for asset library.
public struct AssetLibraryConfiguration {
  let categories: [AssetLibraryCategory]?
  let view: (([AssetLibraryCategory]) -> any AssetLibrary)?
  let modifications: [CategoryModifications]
  let includeAVResources: Bool

  /// Creates asset library configuration.
  public init(_ configure: (inout Builder) -> Void) {
    var builder = Builder()
    configure(&builder)
    categories = builder.categories
    view = builder.view
    modifications = builder.modifications
    includeAVResources = builder.includeAVResources
  }

  /// Builder for asset library configuration.
  public struct Builder {
    /// The categories to use.
    ///
    /// If set, these replace the editor's default categories entirely.
    /// Modifications are applied on top of these categories.
    var categories: [AssetLibraryCategory]?

    /// The asset library view factory.
    ///
    /// If set, this completely replaces the default asset library view.
    /// The closure receives the (possibly modified) categories.
    var view: (([AssetLibraryCategory]) -> any AssetLibrary)?

    /// The category modifications.
    var modifications: [CategoryModifications] = []

    /// Whether video and audio categories are included in the asset library.
    ///
    /// When `false` (the default), categories with IDs `AssetLibraryCategory.ID.videos`
    /// and `AssetLibraryCategory.ID.audio` are removed before the library is created.
    /// Set to `true` in video-oriented editors.
    public var includeAVResources: Bool = false

    /// Sets the categories, replacing the editor's defaults.
    ///
    /// Use this when you want to define the complete set of categories.
    /// Modifications via `modify(_:)` are still applied on top of these categories.
    ///
    /// Example:
    /// ```swift
    /// builder.categories([
    ///   .defaultImages,
    ///   .defaultText,
    ///   .init(id: "custom", title: "Custom", icon: Image(systemName: "star"), sections: [...])
    /// ])
    /// ```
    ///
    /// - Parameter categories: The categories to use.
    public mutating func categories(_ categories: [AssetLibraryCategory]) {
      self.categories = categories
    }

    /// Sets the asset library view factory.
    ///
    /// Use this to completely replace the default asset library with a custom view.
    /// If you only want to modify categories, use `modify(_:)` instead.
    ///
    /// - Parameter view: A closure that receives categories and returns an asset library view.
    public mutating func view(_ view: @escaping ([AssetLibraryCategory]) -> any AssetLibrary) {
      self.view = view
    }

    /// Adds a category modification. Modifications accumulate in order.
    ///
    /// Use this to add, remove, or modify library categories without replacing the entire view.
    ///
    /// Example:
    /// ```swift
    /// builder.modify { categories in
    ///   // Add a section to the images category
    ///   categories.modifySections(of: AssetLibraryCategory.ID.images) { sections in
    ///     sections.addFirst(.image(id: "unsplash", title: "Unsplash", source: .init(id: "unsplash")))
    ///   }
    ///   // Remove the audio category
    ///   categories.remove(id: AssetLibraryCategory.ID.audio)
    /// }
    /// ```
    ///
    /// - Parameter modification: A closure that receives a category modifier.
    public mutating func modify(_ modification: @escaping CategoryModifications) {
      modifications.append(modification)
    }
  }
}
