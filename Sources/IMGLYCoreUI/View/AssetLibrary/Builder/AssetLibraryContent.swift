import SwiftUI

/// An interface for hierarchical asset library content.
@MainActor
public protocol AssetLibraryContent {
  /// The stable identity of the entity associated with this instance. Suitable to conform to `Identifiable`.
  var id: Int { get }
  /// All asset source definitions that belong to this content including all sources of its children.
  var sources: [AssetLoader.SourceData] { get }
  /// A view representation of this content.
  var view: AnyView { get }

  /// Helper utility to print the content hierrachy for debugging.
  func debugPrint(_ level: Int)
}

public extension AssetLibraryContent {
  /// A Boolean value indicating whether this content is empty.
  var isEmpty: Bool { sources.isEmpty }
}

struct AssetLibraryContent_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
