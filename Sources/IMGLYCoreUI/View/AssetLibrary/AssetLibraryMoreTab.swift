@_spi(Internal) import IMGLYCore
import SwiftUI

/// Use this view if you have more than five ``AssetLibraryTab``s to workaround various SwiftUI `TabView` shortcomings.
public struct AssetLibraryMoreTab<Content: View>: View {
  @ViewBuilder private let content: () -> Content

  /// Creates a more tab with `content`.
  /// - Parameter content: The content of the more tab.
  public init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }

  private let title: LocalizedStringResource = .imgly.localized("ly_img_editor_asset_library_title_more")
  @Environment(\.imglyDismissButtonView) private var dismissButtonView

  public var body: some View {
    NavigationView {
      MoreList(content: content)
        .navigationTitle(Text(title))
        .toolbar {
          ToolbarItem {
            dismissButtonView
          }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    .navigationViewStyle(.stack)
    .imgly.searchableAssetLibraryTab()
    .tabItem {
      Label {
        Text(title)
      } icon: {
        Image(systemName: "ellipsis")
      }
    }
    .tag(title.key)
  }
}

private struct MoreList<Content: View>: View {
  @ViewBuilder let content: () -> Content

  @EnvironmentObject private var searchQuery: AssetLibrarySearchQuery

  var body: some View {
    List {
      content()
        .environment(\.imglyIsAssetLibraryMoreTab, true)
    }
    .listStyle(.inset)
    .onAppear {
      searchQuery.value = .init()
    }
  }
}

struct AssetLibraryMoreTabKey: EnvironmentKey {
  static let defaultValue: Bool = false
}

extension EnvironmentValues {
  var imglyIsAssetLibraryMoreTab: Bool {
    get { self[AssetLibraryMoreTabKey.self] }
    set { self[AssetLibraryMoreTabKey.self] = newValue }
  }
}

struct AssetLibraryMoreTab_Previews: PreviewProvider {
  static var previews: some View {
    defaultAssetLibraryPreviews
  }
}
