@_spi(Internal) import IMGLYCore
import SwiftUI

struct SearchableAssetLibraryTab: ViewModifier {
  @StateObject private var searchState = AssetLibrarySearchState()
  @StateObject private var searchQuery = AssetLibrarySearchQuery(initialValue: .init())

  func body(content: Content) -> some View {
    content
      .overlay(alignment: .top) {
        SearchOverlay()
      }
      .environmentObject(searchQuery)
      .environmentObject(searchState)
  }
}

struct SearchableAssetLibraryTab_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
