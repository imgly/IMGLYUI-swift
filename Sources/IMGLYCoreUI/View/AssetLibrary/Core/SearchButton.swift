import SwiftUI

struct SearchButton: View {
  @EnvironmentObject private var searchState: AssetLibrarySearchState
  @EnvironmentObject private var searchQuery: AssetLibrarySearchQuery

  var body: some View {
    Button {
      searchState.isPresented = true
    } label: {
      Label {
        Text(.imgly.localized("ly_img_editor_asset_library_button_search"))
      } icon: {
        Image(systemName: "magnifyingglass")
      }
      .font(.body.weight(.semibold))
    }
  }
}

struct SearchButton_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
