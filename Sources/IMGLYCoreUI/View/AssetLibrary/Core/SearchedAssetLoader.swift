@_spi(Internal) import IMGLYCore
import SwiftUI

struct SearchedAssetLoader: ViewModifier {
  @Environment(\.imglyAssetLibrarySources) private var sources
  @EnvironmentObject private var search: AssetLibrarySearchQuery

  func body(content: Content) -> some View {
    content
      .imgly.assetLoader(sources: sources, search: $search.debouncedValue)
  }
}

struct SearchedAssetLoader_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
