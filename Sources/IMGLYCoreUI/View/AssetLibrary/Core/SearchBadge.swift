@_spi(Internal) import IMGLYCore
import SwiftUI

struct SearchBadge: View {
  @EnvironmentObject private var searchState: AssetLibrarySearchState
  @EnvironmentObject private var searchQuery: AssetLibrarySearchQuery
  @Environment(\.controlSize) private var controlSize

  let searchText: String

  private var leadingPadding: CGFloat {
    switch controlSize {
    case .mini, .small: return 11
    case .regular, .large, .extraLarge: return 14
    @unknown default: return 14
    }
  }

  private var trailingPadding: CGFloat {
    switch controlSize {
    case .mini, .small: return 6
    case .regular, .large, .extraLarge: return 8
    @unknown default: return 8
    }
  }

  private var verticalPadding: CGFloat {
    switch controlSize {
    case .mini, .small: return 5
    case .regular, .large, .extraLarge: return 7
    @unknown default: return 7
    }
  }

  var body: some View {
    HStack {
      Button {
        searchState.isPresented = true
      } label: {
        Text(searchText)
      }
      Button {
        searchQuery.value = .init()
      } label: {
        Label("Remove Search Query", systemImage: "xmark.circle.fill")
          .labelStyle(.iconOnly)
      }
    }
    .buttonStyle(.borderless)
    .imageScale(.medium)
    .padding(.leading, leadingPadding)
    .padding(.trailing, trailingPadding)
    .padding([.top, .bottom], verticalPadding)
    .background {
      Capsule()
        .fill(.bar)
    }
  }
}

struct SearchBadge_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
