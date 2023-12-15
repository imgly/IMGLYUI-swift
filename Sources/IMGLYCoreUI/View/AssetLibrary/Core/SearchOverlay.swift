@_spi(Internal) import IMGLYCore
import SwiftUI

struct SearchOverlay: View {
  @EnvironmentObject private var searchState: AssetLibrarySearchState
  @EnvironmentObject private var searchQuery: AssetLibrarySearchQuery
  @FocusState private var isFocused: Bool

  @ViewBuilder var searchBar: some View {
    HStack(spacing: 14) {
      SearchField(searchText: .init {
        searchQuery.value.query ?? ""
      } set: {
        if searchQuery.value.query ?? "" != $0 {
          searchQuery.value = .init(query: $0)
        }
      }, prompt: searchState.prompt)
        .focused($isFocused)
        .onChange(of: isFocused) { newValue in
          if !newValue, searchState.isPresented {
            searchState.isPresented = false
          }
        }
      Button {
        searchState.isPresented = false
      } label: {
        SwiftUI.Label("Cancel", systemImage: "xmark")
      }
      .labelStyle(.titleOnly)
      .imageScale(.large)
    }
    .padding([.leading, .trailing], 16)
    .padding(.top, 11)
    .padding(.bottom, 8)
    .background(.bar)
  }

  var body: some View {
    VStack(alignment: .trailing, spacing: 8) {
      searchBar
        .opacity(searchState.isPresented ? 1 : 0)
        .disabled(!searchState.isPresented)
        .preference(key: PresentationDragIndicatorHiddenKey.self, value: searchState.isPresented)
        .onChange(of: searchState.isPresented) { newValue in
          isFocused = newValue
        }

      if let searchText = searchQuery.value.query, !searchText.isEmpty, !searchState.isPresented {
        SearchBadge(searchText: searchText)
          .frame(maxWidth: 144, alignment: .trailing)
          .lineLimit(1)
          .padding([.leading, .trailing], 16)
      }
    }
  }
}

@_spi(Internal) public struct PresentationDragIndicatorHiddenKey: PreferenceKey {
  @_spi(Internal) public static let defaultValue: Bool = false
  @_spi(Internal) public static func reduce(value: inout Bool, nextValue: () -> Bool) {
    value = value || nextValue()
  }
}

struct SearchOverlay_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
